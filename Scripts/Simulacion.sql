USE [Banco]
GO

DECLARE @xmlData XML

SET @xmlData = 
		(SELECT *
		FROM OPENROWSET(BULK 'C:\Users\Jota\Desktop\BSL2021\Scripts\DatosTarea2.xml', SINGLE_BLOB) 
		AS xmlData);

DECLARE @FechasProcesar TABLE (Fecha date)
INSERT INTO @FechasProcesar(Fecha)
SELECT T.Item.value('@Fecha', 'DATE')--<campo del XML para fecha de operacion>
FROM @xmlData.nodes('Datos/FechaOperacion') as T(Item) --<documento XML>

DECLARE @outCodeResult int = 0
DECLARE @fechaInicial DATE, @fechaFinal DATE, @DiaCierreEC int
DECLARE @CuentasCierran TABLE(Sec int IDENTITY(1,1), IdEstadoCuenta Int)
DECLARE @TipoOperacion int
DECLARE @lo1 int, @hi1 int, @IdCuentaCierre int

DECLARE @SaldoMinimo money, @MultaSaldoMin money, @QCajeroAutomatico int, @QCajeroHumano int,
	@CargoAnual int, @ComisionHumano int, @ComisionAutomatico int, @InteresSaldoMinimo int,
	@TipoCuentaAhorro int, @SaldoMinimoMes money, @IdMonedaCuenta int

SELECT @fechaInicial=MIN(Fecha), @fechaFinal=MAX(Fecha) FROM @FechasProcesar

WHILE @fechaInicial<=@fechaFinal
BEGIN

		--Insertar Personas
		INSERT INTO [dbo].[Persona](
			[IdTipoIdentidad],
			[Nombre],
			[ValorDocumentoIdentidad],
			[FechaDeNacimiento],
			[Email],
			[Telefono1],
			[Telefono2])
		SELECT 
			T.Item.value('@TipoDocuIdentidad','INT'),
			T.Item.value('@Nombre', 'VARCHAR(64)'),
			T.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(32)'),
			T.Item.value('@FechaNacimiento','DATE'),
			T.Item.value('@Email', 'VARCHAR(32)'),
			T.Item.value('@Telefono1','VARCHAR(16)'),
			T.Item.value('@Telefono2','VARCHAR(16)')
		FROM @xmlData.nodes('Datos/FechaOperacion/AgregarPersona') as T(Item)
		WHERE T.Item.value('../@Fecha', 'DATE') = @fechaInicial;


	--CuentaAhorros
	DECLARE @TempCuentas TABLE
		(Saldo money,
		Fecha date,
		TipoCuenta INT,
		IdentidadCliente VARCHAR(32),  -- Valor DocumentoId del duenno de la cuenta
		NumeroCuenta VARCHAR(32))

	INSERT INTO @TempCuentas(
		NumeroCuenta,
		Saldo,
		Fecha,
		IdentidadCliente,
		TipoCuenta)
	SELECT T.Item.value('@NumeroCuenta','VARCHAR(32)'),
		T.Item.value('@Saldo','MONEY'),
		@fechaInicial,
		T.Item.value('@ValorDocumentoIdentidadDelCliente','VARCHAR(32)'),
		T.Item.value('@TipoCuentaId','INT')
	FROM @xmlData.nodes('Datos/FechaOperacion/AgregarCuenta') as T(Item)
	WHERE T.Item.value('../@Fecha', 'DATE') = @fechaInicial;



		-- Mapeo @TempCuentas-CuentaAhorro
		INSERT INTO [dbo].[CuentaAhorro](
			[IdCliente], 
			[NumeroCuenta], 
			[Saldo], 
			[FechaConstitucion],
			[IdTipoCuentaAhorro])
		SELECT 
			P.ID,
			C.NumeroCuenta,
			C.Saldo,
			C.Fecha,
			C.TipoCuenta
		FROM @TempCuentas C, [dbo].[Persona] P 
		WHERE C.IdentidadCliente=P.[ValorDocumentoIdentidad]
	


	--Insertar Beneficiario
	DECLARE @TempBeneficiario TABLE
		(NumeroCuenta varchar(32),
		ValorDocumentoIdentidadBeneficiario varchar(32),
		ParentezcoId INT,
		Porcentaje int)

	INSERT INTO @TempBeneficiario(
		NumeroCuenta,
		ValorDocumentoIdentidadBeneficiario,
		ParentezcoId,
		Porcentaje)
	SELECT T.Item.value('@NumeroCuenta','VARCHAR(32)'),
		T.Item.value('@ValorDocumentoIdentidadBeneficiario','VARCHAR(32)'),
		T.Item.value('@ParentezcoId','INT'),
		T.Item.value('@Porcentaje','INT')
	FROM @xmlData.nodes('Datos/FechaOperacion/AgregarBeneficiario') as T(Item)
	WHERE T.Item.value('../@Fecha', 'DATE') = @fechaInicial;



	-- Mapeo @@TempBeneficiario-Beneficiario
	INSERT INTO [dbo].[Beneficiario](
		[IdCliente], 
		[IdCuentaAhorro], 
		[NumeroCuenta], 
		[Porcentaje],
		[IdBeneficiario],
		[IdParentesco]
		)
	SELECT C.IdCliente,
		C.ID,
		C.NumeroCuenta,
		B.Porcentaje,
		P.ID,
		B.ParentezcoId
	FROM @TempBeneficiario B, [dbo].[CuentaAhorro] C, [dbo].[Persona] P
	WHERE C.NumeroCuenta=B.NumeroCuenta
		AND P.ValorDocumentoIdentidad=B.ValorDocumentoIdentidadBeneficiario
	

	
	--Insertat TipodeCambio
	INSERT INTO [dbo].[TipoCambio](
		[Fecha],
		[CompraTC],
		[VentaTC],
		[IdMoneda])
	SELECT @fechaInicial,
		T.Item.value('@Compra','MONEY'),
		T.Item.value('@Venta','MONEY'),
		1
	FROM @xmlData.nodes('Datos/FechaOperacion/TipoCambioDolares') as T(Item)
	WHERE T.Item.value('../@Fecha', 'DATE') = @fechaInicial;


	
	DECLARE @TempMovimientos TABLE (
		Descripcion varchar(64),
		Fecha date,
		Monto money,
		NuevoSaldo money,
		NumeroCuenta int,
		IdMoneda int,
		IdTipoMovimiento int)


	--Insertar Movimientos
	INSERT INTO @TempMovimientos(
		Descripcion,
		Fecha,
		Monto,
		NuevoSaldo,
		NumeroCuenta,
		IdMoneda,
		IdTipoMovimiento)
	SELECT T.Item.value('@Descripcion','VARCHAR(64)'),
		@fechaInicial,
		T.Item.value('@Monto','MONEY'),
		0,
		T.Item.value('@NumeroCuenta','VARCHAR(32)'),
		T.Item.value('@IdMoneda','INT'),
		T.Item.value('@Tipo','INT')
	FROM @xmlData.nodes('Datos/FechaOperacion/Movimientos') as T(Item)
	WHERE T.Item.value('../@Fecha', 'DATE') = @fechaInicial;


	--Inserta en tabla movimientos
	INSERT INTO [dbo].[MovimientoCA](
		[Descripcion],
		[Fecha],
		[Monto],
		[NuevoSaldo],
		[IdCuentaAhorro],
		[IdTipoMovimientoCA],
		[IdEstadoCuenta],
		[IdMoneda])
	SELECT T.Descripcion,
		@fechaInicial,
		T.Monto,
		C.Saldo,
		C.ID,
		T.IdTipoMovimiento,
		E.ID,
		T.IdMoneda
	FROM @TempMovimientos T, [dbo].[CuentaAhorro] C, [dbo].[EstadoCuenta] E
	WHERE T.NumeroCuenta = C.NumeroCuenta
		AND E.[IdCuentaAhorro] = C.ID
			AND E.[FechaFin] >= @fechaInicial

	
	EXEC dbo.CerrarEstadosCuenta @fechaInicial, 0

	--.... cargar en tabla variable las cuentas que fueron creada en dia que corresponde a datepart(@fechaInicial, d)
		 
	SET @DiaCierreEC=datepart(d, @fechaInicial)
	-- considerar hacer ajustes a DiaCierreEC considerando meses de 30 y 31 dias, o annos bisiestos
	INSERT @CuentasCierran(IdEstadoCuenta)
	SELECT C.ID 
	FROM [dbo].[EstadoCuenta] C 
	WHERE datepart(d, C.FechaInicio)>=@DiaCierreEC
		 
	SELECT @lo1=1, @hi1=MAX(Sec) FROM @CuentasCierran
		 
	WHILE @lo1<=@hi1
		BEGIN
			SELECT @IdCuentaCierre=C.IdEstadoCuenta FROM @CuentasCierran C WHERE Sec=@lo1

			SELECT
				@SaldoMinimo=T.SaldoMinimo,
				@MultaSaldoMin=T.MultaSaldoMin,
				@QCajeroAutomatico=T.NumRetirosAutomaticos,
				@QCajeroHumano=T.NumRetirosHumanos,
				@CargoAnual=T.CargoAnual,
				@ComisionAutomatico=T.ComisionAutomatico,
				@ComisionHumano=T.ComisionHumano,
				@TipoCuentaAhorro=T.ID,
				@InteresSaldoMinimo=T.Interes,
				@SaldoMinimoMes=E.SaldoMinimoMes,
				@IdMonedaCuenta = C.IdMoneda
			FROM [dbo].[TipoCuentaAhorro] T, [dbo].[EstadoCuenta] E,
				[dbo].[TipoCuentaAhorro] C
			WHERE T.Id=
			(SELECT [IdTipoCuentaAhorro] FROM [dbo].[CuentaAhorro] WHERE ID=
			(SELECT [IdCuentaAhorro] FROM [dbo].[EstadoCuenta]))
				AND E.ID=@IdCuentaCierre AND E.IdCuentaAhorro = C.ID

			--- Calcular intereses respecto del saldo minimo durante el mes, agregar credito por interes 
			--- ganado y afectar saldo
			EXEC dbo.InteresSaldoMinimo @IdCuentaCierre, @fechaInicial, @SaldoMinimoMes,
				@InteresSaldoMinimo, @IdMonedaCuenta, 0

			--- calcular multa por incumplimiento de saldo minimo y agregar movimiento debito y afecta saldo.
			--Inserta en tabla movimientos
			EXEC dbo.CheckearSaldoMinimo @IdCuentaCierre, @fechaInicial, @SaldoMinimo,
				@MultaSaldoMin, @IdMonedaCuenta, 0
			
			--- cobro de comision por exceso de operaciones en ATM. Debito
			EXEC dbo.CheckearQOperacionesAutomatico @IdCuentaCierre, @fechaInicial, @QCajeroAutomatico,
				@ComisionAutomatico, @IdMonedaCuenta, 0
			
			--- cobro de comision por exceso de operaciones en cajero humano. Debito
			EXEC dbo.CheckearQOperacionesHumano @IdCuentaCierre, @fechaInicial, @QCajeroHumano,
				@ComisionHumano, @IdMonedaCuenta, 0

			--- cobro de cargos por servicio. Debito.
			EXEC dbo.CobrarInteresMensual @IdCuentaCierre, @fechaInicial, @CargoAnual,
				@IdMonedaCuenta, 0

			-- cerrar el estado de cuenta (actualizar valores, como saldo final, y otros)
			INSERT INTO [dbo].[EstadoCuenta](
				[FechaInicio],
				[FechaFin],
				[SaldoInicial],
				[SaldoFinal],
				[IdCuentaAhorro],
				[QOperacionesHumano],
				[QOperacionesATM],
				[SaldoMinimoMes])
			SELECT
				E.FechaFin,
				dateadd(m, 1, E.FechaFin),
				C.Saldo,
				C.Saldo,
				E.IdCuentaAhorro,
				0,
				0,
				E.SaldoFinal
			FROM [dbo].[EstadoCuenta] E, [dbo].[CuentaAhorro] C
			WHERE E.ID=@IdCuentaCierre
				AND C.ID=E.IdCuentaAhorro

			SET @lo1=@lo1+1

		END

	SET @fechaInicial=dateadd(d, 1, @fechaInicial)
END;
