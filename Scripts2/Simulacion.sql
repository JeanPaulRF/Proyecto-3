USE [Banco]
GO

DECLARE @xmlData XML

SET @xmlData = 
		(SELECT *
		FROM OPENROWSET(BULK 'C:\Archivos\DatosTarea-3.xml', SINGLE_BLOB) 
		AS xmlData);

DECLARE @FechasProcesar TABLE (Fecha date)
INSERT INTO @FechasProcesar(Fecha)
SELECT T.Item.value('@Fecha', 'DATE')--<campo del XML para fecha de operacion>
FROM @xmlData.nodes('Datos/FechaOperacion') as T(Item) --<documento XML>


DECLARE @fechaInicial DATE, @fechaFinal DATE, @DiaCierreEC int, @DiaAhorroCO int
DECLARE @CuentasCierran TABLE(Sec int IDENTITY(1,1), IdEstadoCuenta Int, IdCuenta int)
DECLARE @TempInteresCO TABLE(Sec int identity(1,1), IDCO int, IdCuenta int, MontoIntereses float)
DECLARE @TempDepositosCO TABLE(Sec int identity(1,1), IDCO int, IdCuenta int, Monto money)
DECLARE @TempRedencionCO TABLE(Sec int identity(1,1), IDCO int, IdCuenta int, MontoRedencia float)
DECLARE @CuentasProcesar TABLE(Sec int, IdCuenta int)
DECLARE @COAhorrar TABLE(Sec int IDENTITY(1,1), IdCO int)
DECLARE @TipoOperacion int, @idCuenta int
DECLARE @lo1 int, @hi1 int, @IdCuentaCierre int, @lo2 int, @hi2 int, @IdCO int

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
	WHERE T.Item.value('../@Fecha', 'DATE') = @fechaInicial


--INSERTAR CUENTAS OBJETIVO----------------
	DECLARE @TempCO TABLE(
		CuentaMaestra varchar(32),
		Codigo varchar(32),
		MontoAhorrar money,
		FechaFinal date,
		DiaMes int,	
		Descripcion varchar(64))

	INSERT INTO @TempCO(
		CuentaMaestra,
		Descripcion,
		DiaMes,
		FechaFinal,
		MontoAhorrar,
		Codigo)
	SELECT T.Item.value('@CuentaMaestra','VARCHAR(32)'),
		T.Item.value('@Descripcion','VARCHAR(64)'),
		T.Item.value('@DiadeAhorro','INT'),
		T.Item.value('@FechaFinal','DATE'),
		T.Item.value('@MontoAhorrar','MONEY'),
		T.Item.value('@NumeroCO','VARCHAR(32)')
	FROM @xmlData.nodes('Datos/FechaOperacion/AgregarCO') as T(Item)
	WHERE T.Item.value('../@Fecha','DATE') = @fechaInicial


	INSERT INTO [dbo].[CuentaObjetivo](
		[FechaInicio],
		[FechaFin],
		[Costo],
		[Objetivo],
		[Saldo],
		[InteresAcumulado],
		[IdCuentaAhorro],
		[DiaAhorro],
		[MesesAhorrados],
		[CodigoCuenta])
	SELECT
		@fechaInicial,
		T.FechaFinal,
		T.MontoAhorrar,
		T.Descripcion,
		0,
		0,
		C.ID,
		T.DiaMes,
		0,
		T.Codigo
	FROM @TempCO T, [dbo].[CuentaAhorro] C
	WHERE T.CuentaMaestra=C.NumeroCuenta

	-----------------------------------

	DECLARE @TempMovimientos TABLE (
		Descripcion varchar(64),
		Monto money,
		NumeroCuenta varchar(32),
		IdMoneda int,
		IdTipoMovimiento int,
		IdCuenta int)

	--INSERTA MOVIMIENTOS
	INSERT INTO @TempMovimientos(
		Descripcion,
		Monto,
		NumeroCuenta,
		IdMoneda,
		IdTipoMovimiento)
	SELECT T.Item.value('@Descripcion','VARCHAR(64)'),
		T.Item.value('@Monto','MONEY'),
		T.Item.value('@NumeroCuenta','VARCHAR(32)'),
		T.Item.value('@IdMoneda','INT'),
		T.Item.value('@Tipo','INT')
	FROM @xmlData.nodes('Datos/FechaOperacion/Movimientos') as T(Item)
	WHERE T.Item.value('../@Fecha', 'DATE') = @fechaInicial;

	UPDATE @TempMovimientos
	SET IdCuenta=C.ID 
	FROM @TempMovimientos T, [dbo].[CuentaAhorro] C 
	WHERE T.NumeroCuenta=C.NumeroCuenta


	--INSERTA EL INTERES-CO
	INSERT INTO @TempInteresCO(IDCO, IdCuenta, MontoIntereses)
	SELECT C.ID, C.IdCuentaAhorro, 0
	FROM [dbo].[CuentaObjetivo] C 
	WHERE C.DiaAhorro=datepart(d, @fechaInicial) AND C.Activo=1

	UPDATE @TempInteresCO
	SET MontoIntereses=T.TasaInteres
	FROM [dbo].[CuentaObjetivo] C, [dbo].[TasaInteres] T
	WHERE C.MesesAhorrados=T.ID AND C.Activo=1


	--INSERTAR DEPOSITOS CO
	INSERT INTO @TempDepositosCO(IDCO, IdCuenta, Monto)
	SELECT C.ID, C.IdCuentaAhorro, C.Costo
	FROM [dbo].[CuentaObjetivo] C
	WHERE C.DiaAhorro=datepart(d, @fechaInicial) AND C.Activo=1

	--INSERTAR REDENCION CO
	INSERT INTO @TempRedencionCO(IDCO, IdCuenta, MontoRedencia)
	SELECT C.ID, C.IdCuentaAhorro, C.InteresAcumulado
	FROM [dbo].[CuentaObjetivo] C
	WHERE C.FechaFin=@fechaInicial AND C.Activo=1

	
	EXEC dbo.CerrarEstadosCuenta @fechaInicial, 0

	--INSERTAR CIERRRE ESTADO CUENTA 
	SET @DiaCierreEC=datepart(d, @fechaInicial)
	-- considerar hacer ajustes a DiaCierreEC considerando meses de 30 y 31 dias, o annos bisiestos
	INSERT @CuentasCierran(IdEstadoCuenta, IdCuenta)
	SELECT C.ID,
		C.IdCuentaAhorro
	FROM [dbo].[EstadoCuenta] C 
	WHERE datepart(d, C.FechaInicio)>=@DiaCierreEC


	--INSERTAR CUENTAS PROCESAR
	;WITH CTE_todascuenta (IDCuenta) as(
		SELECT MF.IdCuenta
		FROM @TempMovimientos MF
		UNION
		SELECT I.IdCuenta
		FROM @TempInteresCO I
		UNION
		SELECT D.IdCuenta
		FROM @TempDepositosCO D
		UNION
		SELECT R.IdCuenta
		FROM @TempRedencionCO R
		UNION
		SELECT EC.IdCuenta
		FROM @CuentasCierran EC
	)
	INSERT @CuentasProcesar(IdCuenta)
	SELECT IdCuenta
	FROM CTE_todascuenta
	ORDER BY IdCuenta


	--WHILE
	SELECT @lo2=min(sec), @hi2=max(sec)
	FROM @CuentasProcesar
	
	WHILE @lo2<=@hi2
	BEGIN
		SELECT @idCuenta=P.IdCuenta
		FROM @CuentasProcesar P
		WHERE P.Sec=@lo2
		
		-- preprocesar muchas cosas
		BEGIN TRANSACTION TprocUnacuenta

			
			--Inserta en tabla movimientos corrientes
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
				T.IdCuenta,
				T.IdTipoMovimiento,
				E.ID,
				T.IdMoneda
			FROM @TempMovimientos T, [dbo].[CuentaAhorro] C, [dbo].[EstadoCuenta] E, @CuentasProcesar P
			WHERE T.IdCuenta = @idCuenta
				AND T.IdCuenta=C.ID
					AND E.[IdCuentaAhorro] = C.ID
						AND E.[FechaFin] >= @fechaInicial
							AND P.Sec=@lo2


			--Insertar Interes en movimiento Interes
			INSERT INTO [dbo].[MovimientoInteresCO](
				[Fecha],
				[Monto],
				[NuevoSaldoAcumulado],
				[IdCuentaObjetivo])
			SELECT @fechaInicial,
				I.MontoIntereses,
				M.NuevoSaldoAcumulado+I.MontoIntereses,
				I.IDCO
			FROM @TempInteresCO I, [MovimientoInteresCO] M, 
				@CuentasProcesar P, [dbo].[CuentaObjetivo] CO
			WHERE I.IdCuenta=@idCuenta
				AND CO.ID=I.IDCO
					AND P.Sec=@lo2

			
			-- hacer depositos de cuentas CO
				--Colocar movimientoCA
				INSERT INTO [dbo].[MovimientoCA](
					[Descripcion],
					[Fecha],
					[Monto],
					[NuevoSaldo],
					[IdCuentaAhorro],
					[IdTipoMovimientoCA],
					[IdEstadoCuenta],
					[IdMoneda])
				SELECT TC.Nombre,
					@fechaInicial,
					D.Monto,
					CA.Saldo,
					@idCuenta,
					14,
					E.ID,
					T.IdMoneda
				FROM [dbo].[TipoCuentaAhorro] T, [dbo].[CuentaObjetivo] CO,
					@CuentasProcesar P, [dbo].[CuentaAhorro] CA,
					@TempDepositosCO D, [dbo].[EstadoCuenta] E,
					TipoMovimientoCA TC
				WHERE P.Sec=@lo2
					AND CA.ID=@idCuenta AND CO.ID=D.IDCO
					AND CO.IdCuentaAhorro=@idCuenta
					AND E.[FechaFin] >= @fechaInicial
					AND CA.IdTipoCuentaAhorro=T.ID
					AND TC.ID=14
					AND CA.Saldo-D.Monto>=0

				--Colocar MovimientoCO
				INSERT INTO [dbo].[MovimientoCO](
					[Fecha],
					[Monto],
					[NuevoSaldo],
					[IdCuentaObjetivo],
					[IdTipoMovimientoCO])
				SELECT @fechaInicial,
					D.Monto,
					CO.Saldo+D.Monto,
					CO.ID,
					1
				FROM @TempDepositosCO D, CuentaObjetivo CO, @CuentasProcesar P,
					CuentaAhorro CA
				WHERE CO.IdCuentaAhorro=@idCuenta
					AND CO.ID=D.IDCO AND P.Sec=@lo2
					AND CO.IdCuentaAhorro=CA.ID
					AND CA.Saldo-D.Monto>=0
			




			-- hacer redencion de saldo de cuentas CO
			INSERT INTO [dbo].[MovimientoCA](
					[Descripcion],
					[Fecha],
					[Monto],
					[NuevoSaldo],
					[IdCuentaAhorro],
					[IdTipoMovimientoCA],
					[IdEstadoCuenta],
					[IdMoneda])
				SELECT TC.Nombre,
					@fechaInicial,
					CO.Saldo,
					CA.Saldo,
					@idCuenta,
					15,
					E.ID,
					T.IdMoneda
				FROM [dbo].[TipoCuentaAhorro] T, [dbo].[CuentaObjetivo] CO,
					@CuentasProcesar P, [dbo].[CuentaAhorro] CA,
					@TempRedencionCO D, [dbo].[EstadoCuenta] E,
					TipoMovimientoCA TC
				WHERE P.Sec=@lo2
					AND CA.ID=@idCuenta AND CO.ID=D.IDCO
					AND CO.IdCuentaAhorro=@idCuenta
					AND E.[FechaFin] >= @fechaInicial
					AND CA.IdTipoCuentaAhorro=T.ID
					AND TC.ID=15

				--Colocar MovimientoCO
				INSERT INTO [dbo].[MovimientoCO](
					[Fecha],
					[Monto],
					[NuevoSaldo],
					[IdCuentaObjetivo],
					[IdTipoMovimientoCO])
				SELECT @fechaInicial,
					CO.Saldo*-1,
					0,
					CO.ID,
					3
				FROM @TempRedencionCO D, CuentaObjetivo CO, @CuentasProcesar P
				WHERE CO.IdCuentaAhorro=@idCuenta
					AND CO.ID=D.IDCO AND P.Sec=@lo2

			-- hacer redencion de interes acumulado de cuentas CO
			INSERT INTO [dbo].[MovimientoCA](
					[Descripcion],
					[Fecha],
					[Monto],
					[NuevoSaldo],
					[IdCuentaAhorro],
					[IdTipoMovimientoCA],
					[IdEstadoCuenta],
					[IdMoneda])
				SELECT TC.Nombre,
					@fechaInicial,
					CO.InteresAcumulado,
					CA.Saldo,
					@idCuenta,
					15,
					E.ID,
					T.IdMoneda
				FROM [dbo].[TipoCuentaAhorro] T, [dbo].[CuentaObjetivo] CO,
					@CuentasProcesar P, [dbo].[CuentaAhorro] CA,
					@TempRedencionCO D, [dbo].[EstadoCuenta] E,
					TipoMovimientoCA TC
				WHERE P.Sec=@lo2
					AND CA.ID=@idCuenta AND CO.ID=D.IDCO
					AND CO.IdCuentaAhorro=@idCuenta
					AND E.[FechaFin] >= @fechaInicial
					AND CA.IdTipoCuentaAhorro=T.ID
					AND TC.ID=16

				--Colocar MovimientoCO
				INSERT INTO [dbo].[MovimientoCO](
					[Fecha],
					[Monto],
					[NuevoSaldo],
					[IdCuentaObjetivo],
					[IdTipoMovimientoCO])
				SELECT @fechaInicial,
					CO.InteresAcumulado*-1,
					0,
					CO.ID,
					3
				FROM @TempRedencionCO D, CuentaObjetivo CO, @CuentasProcesar P
				WHERE CO.IdCuentaAhorro=@idCuenta
					AND CO.ID=D.IDCO AND P.Sec=@lo2


			-- cerrar Estado Cuenta
			SELECT @IdCuentaCierre=C.IdEstadoCuenta 
			FROM @CuentasCierran C, @CuentasProcesar P
			WHERE P.Sec=@lo2 AND C.IdCuenta=P.IdCuenta

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
				@InteresSaldoMinimo, @IdMonedaCuenta

			--- calcular multa por incumplimiento de saldo minimo y agregar movimiento debito y afecta saldo.
			--Inserta en tabla movimientos
			EXEC dbo.CheckearSaldoMinimo @IdCuentaCierre, @fechaInicial, @SaldoMinimo,
				@MultaSaldoMin, @IdMonedaCuenta
			
			--- cobro de comision por exceso de operaciones en ATM. Debito
			EXEC dbo.CheckearQOperacionesAutomatico @IdCuentaCierre, @fechaInicial, @QCajeroAutomatico,
				@ComisionAutomatico, @IdMonedaCuenta
			
			--- cobro de comision por exceso de operaciones en cajero humano. Debito
			EXEC dbo.CheckearQOperacionesHumano @IdCuentaCierre, @fechaInicial, @QCajeroHumano,
				@ComisionHumano, @IdMonedaCuenta

			--- cobro de cargos por servicio. Debito.
			EXEC dbo.CobrarInteresMensual @IdCuentaCierre, @fechaInicial, @CargoAnual,
				@IdMonedaCuenta

			-- cerrar el estado de cuenta (actualizar valores, como saldo final, y otros)
			INSERT INTO [dbo].[EstadoCuenta](
				[FechaInicio],
				[FechaFin],
				[SaldoInicial],
				[SaldoFinal],
				[IdCuentaAhorro],
				[QOperacionesHumano],
				[QOperacionesATM])
			SELECT
				E.FechaFin,
				dateadd(m, 1, E.FechaFin),
				E.SaldoFinal,
				E.SaldoFinal,
				E.IdCuentaAhorro,
				0,
				0
			FROM [dbo].[EstadoCuenta] E
			WHERE E.ID=@IdCuentaCierre
		
		COMMIT TRANSACTION TprocUnacuenta
		
	
		SET @lo2=@lo2+1
	END 

	SET @fechaInicial=dateadd(d, 1, @fechaInicial)
END;


  
