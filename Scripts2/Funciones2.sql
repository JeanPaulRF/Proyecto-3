USE BANCO 
GO


CREATE PROCEDURE InsertarCuentaObjetivo(
	@NumeroCuenta varchar(32),
	@Codigo varchar(32),
	@FechaInicio varchar(32),
	@FechaFin varchar(32),
	@Costo int,
	@Objetivo varchar(64),
	@Saldo int,
	@Interes int,
	@DiaAhorro int,
	@outCodeResult int OUTPUT)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		DECLARE @IdCuenta int
		SELECT @IdCuenta=C.ID
		FROM [dbo].[CuentaAhorro] C
		WHERE C.NumeroCuenta=@NumeroCuenta

		BEGIN TRANSACTION T1
			SELECT CAST(@FechaInicio AS date) AS dataconverted;
			SELECT CAST(@FechaFin AS date) AS dataconverted;

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
				@FechaInicio,
				@FechaFin,
				@Costo,
				@Objetivo,
				@Saldo,
				@Interes,
				@IdCuenta,
				@DiaAhorro,
				0,
				@Codigo
		COMMIT TRANSACTION T1
	 END TRY
	 BEGIN CATCH
		IF @@tRANCOUNT>0
			ROLLBACK TRAN T1;
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
	 SELECT @outCodeResult
END;
GO



CREATE PROCEDURE ActualizarCuentaObjetivo(
	@NumeroCuenta varchar(32),
	@FechaInicio varchar(32),
	@FechaFin varchar(32),
	@Objetivo varchar(64),
	@outCodeResult int OUTPUT)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		DECLARE @IdCuenta int
		SELECT @IdCuenta=C.ID
		FROM [dbo].[CuentaObjetivo] C
		WHERE C.CodigoCuenta=@NumeroCuenta

		BEGIN TRANSACTION F2
			SELECT CAST(@FechaInicio AS date) AS dataconverted
			SELECT CAST(@FechaFin AS date) AS dataconverted

			UPDATE [dbo].[CuentaObjetivo]
			SET
				[FechaInicio]=@FechaInicio,
				[FechaFin]=@FechaFin,
				[Objetivo]=@Objetivo
			WHERE [ID]=@IdCuenta
		COMMIT TRANSACTION F2
	 END TRY
	 BEGIN CATCH
		IF @@tRANCOUNT>0
			ROLLBACK TRAN F2;
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
END;
GO


CREATE PROCEDURE ActivacionCuentaObjetivo(
	@NumeroCuenta varchar(32),
	@outCodeResult int OUTPUT)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		DECLARE @IdCuenta int
		SELECT @IdCuenta=C.ID
		FROM [dbo].[CuentaObjetivo] C
		WHERE C.CodigoCuenta=@NumeroCuenta

		BEGIN TRANSACTION F3
			UPDATE [dbo].[CuentaObjetivo]
			SET [Activo]=0
			WHERE [ID]=@IdCuenta AND Activo=1

			UPDATE [dbo].[CuentaObjetivo]
			SET [Activo]=1
			WHERE [ID]=@IdCuenta AND Activo=0
		COMMIT TRANSACTION F3
	 END TRY
	 BEGIN CATCH
		IF @@tRANCOUNT>0
			ROLLBACK TRAN F3;
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
END;
GO




CREATE PROCEDURE dbo.CerrarEstadosCuenta(@Fecha date,
	@outCodeResult int OUTPUT)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
	BEGIN TRANSACTION F4
	UPDATE [dbo].[EstadoCuenta]
	SET Activo=0
	WHERE [FechaFin]<=@Fecha
	COMMIT TRANSACTION F4
	END TRY
	 BEGIN CATCH
		IF @@tRANCOUNT>0
			ROLLBACK TRAN T1;
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
END;
GO



CREATE PROCEDURE dbo.InteresSaldoMinimo(
	@IdCuentaCierre int,
	@Fecha date,
	@SaldoMinimoMes money,
	@Interes money,
	@IdMoneda int,
	@outCodeResult int OUTPUT)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
	BEGIN TRANSACTION F5
		INSERT INTO [dbo].[MovimientoCA](
			[Descripcion],
			[Fecha],
			[Monto],
			[NuevoSaldo],
			[IdCuentaAhorro],
			[IdTipoMovimientoCA],
			[IdEstadoCuenta],
			[IdMoneda])
		SELECT T.Nombre,
			@Fecha,
			(@Interes/12)/100*@SaldoMinimoMes,
			E.SaldoFinal,
			E.IdCuentaAhorro,
			13,
			@IdCuentaCierre,
			@IdMoneda
		FROM [dbo].[TipoMovimientoCA] T, [dbo].[EstadoCuenta] E
		WHERE E.ID=@IdCuentaCierre
	COMMIT TRANSACTION F5
	END TRY
	 BEGIN CATCH
		IF @@tRANCOUNT>0
			ROLLBACK TRANSACTION F5;
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
END;
GO


CREATE PROCEDURE dbo.CheckearSaldoMinimo(
	@IdCuentaCierre int,
	@Fecha date,
	@SaldoMinimo money,
	@MultaSaldoMin money,
	@IdMoneda int,
	@outCodeResult int OUTPUT)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
	BEGIN TRANSACTION F6
	IF (SELECT [SaldoFinal] FROM [dbo].[EstadoCuenta] WHERE [ID]=@IdCuentaCierre) < @SaldoMinimo
	BEGIN
		INSERT INTO [dbo].[MovimientoCA](
			[Descripcion],
			[Fecha],
			[Monto],
			[NuevoSaldo],
			[IdCuentaAhorro],
			[IdTipoMovimientoCA],
			[IdEstadoCuenta],
			[IdMoneda])
		SELECT T.Nombre,
			@Fecha,
			@MultaSaldoMin,
			E.SaldoFinal,
			E.IdCuentaAhorro,
			17,
			@IdCuentaCierre,
			@IdMoneda
		FROM [dbo].[TipoMovimientoCA] T, [dbo].[EstadoCuenta] E
		WHERE E.ID=@IdCuentaCierre
	END
	COMMIT TRANSACTION F6
	END TRY
	 BEGIN CATCH
		IF @@tRANCOUNT>0
			ROLLBACK TRAN F6;
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
END;
GO


CREATE PROCEDURE dbo.CheckearQOperacionesAutomatico(
	@IdCuentaCierre int,
	@Fecha date,
	@QCajeroAutomatico int,
	@ComisionAutomatico int,
	@IdMoneda int,
	@outCodeResult int OUTPUT)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
	BEGIN TRANSACTION F7
	IF (SELECT [QOperacionesATM] FROM [dbo].[EstadoCuenta] WHERE [ID]=@IdCuentaCierre) > 0
	BEGIN
		INSERT INTO [dbo].[MovimientoCA](
			[Descripcion],
			[Fecha],
			[Monto],
			[NuevoSaldo],
			[IdCuentaAhorro],
			[IdTipoMovimientoCA],
			[IdEstadoCuenta],
			[IdMoneda])
		SELECT T.Nombre,
			@Fecha,
			@ComisionAutomatico,
			E.SaldoFinal,
			E.IdCuentaAhorro,
			10,
			@IdCuentaCierre,
			@IdMoneda
		FROM [dbo].[TipoMovimientoCA] T, [dbo].[EstadoCuenta] E
		WHERE E.ID=@IdCuentaCierre
	END
	COMMIT TRANSACTION F7
	END TRY
	 BEGIN CATCH
		IF @@tRANCOUNT>0
			ROLLBACK TRAN F7;
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
END;
GO


CREATE PROCEDURE dbo.CheckearQOperacionesHumano(
	@IdCuentaCierre int,
	@Fecha date,
	@QCajeroHumano int,
	@ComisionHumano int,
	@IdMoneda int,
	@outCodeResult int OUTPUT)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
	BEGIN TRANSACTION F8
	IF (SELECT [QOperacionesHumano] FROM [dbo].[EstadoCuenta] WHERE [ID]=@IdCuentaCierre) > 0
	BEGIN
		INSERT INTO [dbo].[MovimientoCA](
			[Descripcion],
			[Fecha],
			[Monto],
			[NuevoSaldo],
			[IdCuentaAhorro],
			[IdTipoMovimientoCA],
			[IdEstadoCuenta],
			[IdMoneda])
		SELECT T.Nombre,
			@Fecha,
			@ComisionHumano,
			E.SaldoFinal,
			E.IdCuentaAhorro,
			9,
			@IdCuentaCierre,
			@IdMoneda
		FROM [dbo].[TipoMovimientoCA] T, [dbo].[EstadoCuenta] E
		WHERE E.ID=@IdCuentaCierre
	END
	COMMIT TRANSACTION F8
	END TRY
	 BEGIN CATCH
		IF @@tRANCOUNT>0
			ROLLBACK TRAN F8;
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
END;
GO


CREATE PROCEDURE dbo.CobrarInteresMensual(
	@IdCuentaCierre int, 
	@Fecha date, 
	@CargoAnual int,
	@IdMoneda int,
	@outCodeResult int OUTPUT)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
	BEGIN TRANSACTION F9
	INSERT INTO [dbo].[MovimientoCA](
		[Descripcion],
		[Fecha],
		[Monto],
		[NuevoSaldo],
		[IdCuentaAhorro],
		[IdTipoMovimientoCA],
		[IdEstadoCuenta],
		[IdMoneda])
	SELECT T.Nombre,
		@Fecha,
		@CargoAnual/12,
		E.SaldoFinal,
		E.IdCuentaAhorro,
		12,
		@IdCuentaCierre,
		@IdMoneda
	FROM [dbo].[TipoMovimientoCA] T, [dbo].[EstadoCuenta] E
	WHERE E.ID=@IdCuentaCierre
	COMMIT TRANSACTION F9
	END TRY
	 BEGIN CATCH
		IF @@tRANCOUNT>0
			ROLLBACK TRAN F9;
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
END;
GO




--TRIGGERS

CREATE TRIGGER dbo.ActualizarTipoCambio
ON [dbo].[TipoCambio]
AFTER INSERT
AS
BEGIN
	DECLARE @outCodeResult int = 0
	SET NOCOUNT ON
	BEGIN TRY
	DECLARE @IdTipoCambio int
	SET @IdTipoCambio = (SELECT ID FROM Inserted)

	UPDATE [dbo].[Moneda]
	SET [IdTipoCambioFinal]=@IdTipoCambio
	END TRY
	 BEGIN CATCH
		IF @@tRANCOUNT>0
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
END;
GO




CREATE TRIGGER dbo.AplicarMovimiento
ON [dbo].[MovimientoCA] AFTER INSERT
AS
BEGIN
		DECLARE @outCodeResult int = 0

		--Si es el mismo tipo de moneda

		UPDATE [dbo].[CuentaAhorro]
		SET
			Saldo=Saldo+(i.Monto*(-1^T.Operacion)*-1) --realiza el movimiento
		FROM [dbo].[TipoMovimientoCA] T, [dbo].[CuentaAhorro] C, inserted i,
			[dbo].[TipoCuentaAhorro] TC
		WHERE C.ID=i.IdCuentaAhorro
			AND i.IdTipoMovimientoCA=T.ID --busca el tipo de movimiento 
				AND TC.ID=C.IdTipoCuentaAhorro --busca tipo de cuenta
					AND i.IdMoneda=TC.IdMoneda --busca las monedas

		--Si la cuenta es en Dolares y el movimiento es el Colones
		--IF @IdMoneda=1 AND @IdMonedaCuenta=2
		UPDATE [dbo].[CuentaAhorro]
		SET
			Saldo=Saldo+ ( (i.Monto/M.VentaTC) * (-1^T.Operacion) * -1 )  --realiza el movimiento
		FROM [dbo].[CuentaAhorro] C, [dbo].[TipoMovimientoCA] T, [dbo].[TipoCambio] M, 
			[dbo].[Moneda] M2, inserted i, [dbo].[TipoCuentaAhorro] TC
		WHERE C.ID=i.IdCuentaAhorro
			AND i.IdTipoMovimientoCA=T.ID --busca el tipo de movimiento 
				AND TC.ID=C.IdTipoCuentaAhorro --busca tipo de cuenta
					AND M.ID = M2.[IdTipoCambioFinal] --tipo de cambio final
						AND i.IdMoneda=1
							AND TC.IdMoneda=2

		--Si la cuenta es en Colones y el movimiento es el Dolares
		--IF @IdMoneda=2 AND @IdMonedaCuenta=1

		UPDATE [dbo].[CuentaAhorro]
		SET
			Saldo=Saldo+ ( (i.Monto*M.CompraTC) * (-1^T.Operacion) * -1 )  --realiza el movimiento
		FROM [dbo].[CuentaAhorro] C, [dbo].[TipoMovimientoCA] T, [dbo].[TipoCambio] M, 
			[dbo].[Moneda] M2, inserted i, [dbo].[TipoCuentaAhorro] TC
		WHERE C.ID=i.IdCuentaAhorro
			AND i.IdTipoMovimientoCA=T.ID --busca el tipo de movimiento 
				AND TC.ID=C.IdTipoCuentaAhorro --busca tipo de cuenta
					AND M.ID = M2.[IdTipoCambioFinal] --tipo de cambio final
						AND i.IdMoneda=2
							AND TC.IdMoneda=1


		UPDATE [dbo].[MovimientoCA]
		SET NuevoSaldo=C.Saldo
		FROM [dbo].[CuentaAhorro] C, inserted i
		WHERE C.ID=i.IdCuentaAhorro


		UPDATE [dbo].[EstadoCuenta]
		SET QOperacionesHumano = QOperacionesHumano+1
		FROM inserted i, [dbo].[EstadoCuenta] E
		WHERE E.ID=i.IdEstadoCuenta
			AND i.IdTipoMovimientoCA=1 OR i.IdTipoMovimientoCA=7
				AND i.Fecha<E.FechaFin

		UPDATE [dbo].[EstadoCuenta]
		SET QOperacionesATM = QOperacionesATM+1
		FROM inserted i, [dbo].[EstadoCuenta] E
		WHERE E.ID=i.IdEstadoCuenta
			AND i.IdTipoMovimientoCA=2 OR i.IdTipoMovimientoCA=6
				AND i.Fecha<E.FechaFin

		UPDATE [dbo].[EstadoCuenta]
		SET [SaldoFinal]=i.NuevoSaldo
		FROM inserted i, [dbo].[EstadoCuenta] E
		WHERE i.IdEstadoCuenta=E.ID
			AND i.Fecha<E.FechaFin

		UPDATE [dbo].[EstadoCuenta]
		SET SaldoMinimoMes=i.NuevoSaldo
		FROM inserted i, [dbo].[EstadoCuenta] E
		WHERE i.NuevoSaldo<E.SaldoMinimoMes
			AND E.ID=i.IdEstadoCuenta
				AND i.Fecha<E.FechaFin
END;
GO



CREATE TRIGGER dbo.CrearEstadoCuenta
ON [dbo].[CuentaAhorro] AFTER INSERT
AS
BEGIN
	DECLARE @outCodeResult int = 0
	INSERT INTO [dbo].[EstadoCuenta](
		[FechaInicio],
		[FechaFin],
		[SaldoInicial],
		[SaldoFinal],
		[IdCuentaAhorro],
		[QOperacionesATM],
		[QOperacionesHumano],
		[SaldoMinimoMes])
	SELECT 
		C.FechaConstitucion,
		dateadd(m, 1, C.FechaConstitucion),
		C.Saldo,
		C.Saldo,
		i.ID,
		0,
		0,
		C.Saldo
	FROM [dbo].[CuentaAhorro] C, inserted i
	WHERE C.ID=i.ID
END;
GO

/*

CREATE TRIGGER dbo.ActualizarEstadoCuenta
ON [dbo].[MovimientoCA] AFTER UPDATE
AS
BEGIN
	DECLARE @outCodeResult int = 0

	UPDATE [dbo].[EstadoCuenta]
	SET QOperacionesHumano = QOperacionesHumano+1
	FROM inserted i, [dbo].[EstadoCuenta] E
	WHERE E.ID=i.IdEstadoCuenta
		AND i.IdTipoMovimientoCA=1 OR i.IdTipoMovimientoCA=7
			AND i.Fecha<E.FechaFin

	UPDATE [dbo].[EstadoCuenta]
	SET QOperacionesATM = QOperacionesATM+1
	FROM inserted i, [dbo].[EstadoCuenta] E
	WHERE E.ID=i.IdEstadoCuenta
		AND i.IdTipoMovimientoCA=2 OR i.IdTipoMovimientoCA=6
			AND i.Fecha<E.FechaFin

	UPDATE [dbo].[EstadoCuenta]
	SET [SaldoFinal]=i.NuevoSaldo
	FROM inserted i, [dbo].[EstadoCuenta] E
	WHERE i.IdEstadoCuenta=E.ID
		AND i.Fecha<E.FechaFin

	UPDATE [dbo].[EstadoCuenta]
	SET SaldoMinimoMes=i.NuevoSaldo
	FROM inserted i, [dbo].[EstadoCuenta] E
	WHERE i.NuevoSaldo<E.SaldoMinimoMes
		AND E.ID=i.IdEstadoCuenta
			AND i.Fecha<E.FechaFin
END;
GO

*/




--PROCEDURES EXTRA

CREATE PROCEDURE dbo.GetCuentasObjetivo(@NumeroCuenta varchar(32),
	@outCodeResult int OUTPUT)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
	BEGIN TRANSACTION F14
	DECLARE @IdCuenta int
	SET @IdCuenta = 
		(SELECT ID FROM [dbo].[CuentaAhorro] WHERE [NumeroCuenta]=@NumeroCuenta)

	SELECT
		C.[FechaInicio],
		C.[FechaFin],
		C.[Costo],
		C.[Objetivo],
		C.[Saldo],
		C.[InteresAcumulado],
		C.[Activo]
	FROM [dbo].[CuentaObjetivo] C
	WHERE C.[IdCuentaAhorro]=@IdCuenta
	COMMIT TRANSACTION F14
	END TRY
	 BEGIN CATCH
		IF @@tRANCOUNT>0
			ROLLBACK TRAN F14;
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
END;
GO


CREATE PROCEDURE dbo.GetEstadosCuenta(@NumeroCuenta varchar(32),
	@outCodeResult int OUTPUT)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
	BEGIN TRANSACTION F15
	DECLARE @IdCuenta int
	SET @IdCuenta= (SELECT ID FROM [dbo].[CuentaAhorro] WHERE NumeroCuenta=@NumeroCuenta)

	SELECT * FROM [dbo].[EstadoCuenta] WHERE [IdCuentaAhorro]=@IdCuenta
	COMMIT TRANSACTION F15
	END TRY
	 BEGIN CATCH
		IF @@tRANCOUNT>0
			ROLLBACK TRAN F15;
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
END;
GO


CREATE PROCEDURE dbo.GetMovimientosDeEstado(@IdEstadoCuenta int,
	@outCodeResult int OUTPUT)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY

	DECLARE @TempMovimientos TABLE(
		Fecha date,
		Compra money,
		Venta money,
		IdMonedaMovimiento int,
		MontoMovimiento money,
		IdMonedaCuenta int,
		MontoCuenta money,
		Descripcion varchar(64),
		NuevoSaldo money)
	DECLARE @minFecha date, @maxFecha date

	SELECT @minFecha = MIN(Fecha), @maxFecha=MAX(Fecha) FROM [dbo].[MovimientoCA]
		
	WHILE @maxFecha>=@minFecha
	BEGIN
	BEGIN TRANSACTION F16
		INSERT INTO @TempMovimientos(
			Fecha,
			Compra,
			Venta,
			IdMonedaMovimiento,
			MontoMovimiento,
			IdMonedaCuenta,
			MontoCuenta,
			Descripcion,
			NuevoSaldo)
		SELECT
			M.Fecha,
			0,
			0,
			M.IdMoneda,
			M.Monto,
			T.IdMoneda,
			M.Monto,
			M.Descripcion,
			M.NuevoSaldo
		FROM [dbo].[MovimientoCA] M, [dbo].[CuentaAhorro] C,
			[dbo].[TipoCuentaAhorro] T
		WHERE @maxFecha=M.Fecha
			AND M.IdCuentaAhorro=C.ID
				AND C.IdTipoCuentaAhorro=T.ID

		UPDATE @TempMovimientos
		SET
			Compra=T.CompraTC,
			Venta=T.VentaTC,
			MontoCuenta=MontoCuenta*T.CompraTC
		FROM [dbo].[TipoCambio] T
		WHERE IdMonedaCuenta!=IdMonedaMovimiento
			AND T.Fecha=@maxFecha
				AND IdMonedaCuenta=1

		UPDATE @TempMovimientos
		SET
			Compra=T.CompraTC,
			Venta=T.VentaTC,
			MontoCuenta=MontoCuenta/T.VentaTC
		FROM [dbo].[TipoCambio] T
		WHERE IdMonedaCuenta!=IdMonedaMovimiento
			AND T.Fecha=@maxFecha
				AND IdMonedaCuenta=2

		SET @maxFecha=DATEADD(d, -1, @maxFecha)
	END
	COMMIT TRANSACTION F16

	SELECT * FROM @TempMovimientos

	END TRY
	 BEGIN CATCH
		IF @@tRANCOUNT>0
			ROLLBACK TRAN F16;
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
END;
GO


--3 TAREA



CREATE TRIGGER dbo.AplicarMovimientoCO
ON [dbo].[MovimientoCO] AFTER INSERT
AS
BEGIN
	UPDATE [dbo].[CuentaObjetivo]
	SET Saldo=Saldo+i.Monto,
		InteresAcumulado=InteresAcumulado+T.TasaInteres,
		MesesAhorrados=MesesAhorrados+1
	FROM inserted i, MovimientoInteresCO M, TasaInteres T,
		CuentaObjetivo CO
	WHERE i.Fecha=M.Fecha 
		AND i.IdCuentaObjetivo=M.IdCuentaObjetivo
			AND T.ID=CO.MesesAhorrados
END;
GO


CREATE TRIGGER dbo.BitacoraInsertarBeneficiario
ON [dbo].[Beneficiario] AFTER INSERT
AS
BEGIN
	DECLARE @fecha date = GETDATE()
	INSERT INTO [dbo].[Evento](
		[XMLAntes],
		[XMLDespues],
		[IdTipoEvento],
		[IdUser],
		[IP],
		[Fecha])
	SELECT
		'<Beneficiario/>',
		(SELECT * FROM inserted AS Beneficiario FOR XML AUTO),
		1,
		5,
		'0000',
		@fecha
END;
GO


CREATE TRIGGER dbo.BitacoraModificarBeneficiario
ON [dbo].[Beneficiario] AFTER UPDATE
AS
BEGIN
	DECLARE @fecha date = GETDATE()
	INSERT INTO [dbo].[Evento](
		[XMLAntes],
		[XMLDespues],
		[IdTipoEvento],
		[IdUser],
		[IP],
		[Fecha])
	SELECT
		(SELECT * FROM deleted AS Beneficiario FOR XML AUTO),
		(SELECT * FROM inserted AS Beneficiario FOR XML AUTO),
		2,
		5,
		'0000',
		@fecha
	FROM inserted i, deleted d
	WHERE i.Activo=d.Activo --lo modificaron

	INSERT INTO [dbo].[Evento](
		[XMLAntes],
		[XMLDespues],
		[IdTipoEvento],
		[IdUser],
		[IP],
		[Fecha])
	SELECT
		(SELECT * FROM deleted AS Beneficiario FOR XML AUTO),
		'<Beneficiario/>',
		3,
		5,
		'0000',
		@fecha
	FROM inserted i, deleted d
	WHERE i.Activo!=d.Activo --lo desactivaron
END;
GO


CREATE TRIGGER dbo.BitacoraInsertarCO
ON [dbo].[CuentaObjetivo] AFTER INSERT
AS
BEGIN
	DECLARE @fecha date = GETDATE()
	INSERT INTO [dbo].[Evento](
		[XMLAntes],
		[XMLDespues],
		[IdTipoEvento],
		[IdUser],
		[IP],
		[Fecha])
	SELECT
		'<CuentaObjetivo/>',
		(SELECT * FROM inserted AS CuentaObjetivo FOR XML AUTO),
		4,
		5,
		'0000',
		@fecha
END;
GO



CREATE TRIGGER dbo.BitacoraModificarCO
ON [dbo].[CuentaObjetivo] AFTER UPDATE
AS
BEGIN
	DECLARE @fecha date = GETDATE()
	INSERT INTO [dbo].[Evento](
		[XMLAntes],
		[XMLDespues],
		[IdTipoEvento],
		[IdUser],
		[IP],
		[Fecha])
	SELECT
		(SELECT * FROM deleted AS CuentaObjetivo FOR XML AUTO),
		(SELECT * FROM inserted AS CuentaObjetivo FOR XML AUTO),
		5,
		5,
		'0000',
		@fecha
	FROM inserted i, deleted d
	WHERE i.Activo=d.Activo --lo modificaron

	INSERT INTO [dbo].[Evento](
		[XMLAntes],
		[XMLDespues],
		[IdTipoEvento],
		[IdUser],
		[IP],
		[Fecha])
	SELECT
		(SELECT * FROM deleted AS CuentaObjetivo FOR XML AUTO),
		'<CuentaObjetivo/>',
		6,
		5,
		'0000',
		@fecha
	FROM inserted i, deleted d
	WHERE i.Activo!=d.Activo --lo desactivaron
END;
GO




--CONSULTAS

CREATE PROCEDURE dbo.ConsultaA(@outCodeResult int OUT)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY

	BEGIN TRAN C1
	DECLARE @COIncompletas TABLE (Sec int identity(1,1), IdCo int, Meses int, Inicio date, Fin date)

	INSERT INTO @COIncompletas(IdCo, Inicio, Fin)
	SELECT ID, FechaInicio, FechaFin
	FROM CuentaObjetivo

	UPDATE @COIncompletas
	SET [Meses]=datepart(m, Fin)-datepart(m, Inicio)

	UPDATE @COIncompletas
	SET [Meses]=[Meses]+12
	WHERE datepart(y, Fin) > datepart(y, Inicio)

	UPDATE @COIncompletas
	SET [Meses]=[Meses]-1
	WHERE datepart(d, Fin) < datepart(d, Inicio)

	SELECT CO.CodigoCuenta,
		CO.ID,
		CO.Objetivo,
		CO.MesesAhorrados as RetirosRealizadosReal,
		CI.Meses as RetirosRealizadosTotales,
		CO.Saldo as MontoDebitadoReal,
		CO.Saldo+(CI.Meses*CO.Costo) as MontoDebitadoTotal
	FROM @COIncompletas CI, CuentaObjetivo CO
	WHERE CI.IdCo=CO.ID
	AND CI.Meses-CO.MesesAhorrados>0

	COMMIT TRAN C1
	END TRY
	BEGIN CATCH
		IF @@tRANCOUNT>0
			ROLLBACK TRAN C1;
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
END;
GO


CREATE PROCEDURE dbo.ConsultaB(@N2 int,@outCodeResult int OUT )
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY

	BEGIN TRAN C2

	DECLARE @N int = 5
	DECLARE @cuentasConsulta TABLE (Sec INT IDENTITY(1,1), IdCuenta INT) 
	DECLARE @cuentasConsultaFinal TABLE (Sec INT IDENTITY(1,1), IdCuenta INT, QRetiros float, MesMas int, AnoMas int) 
	DECLARE @cantATM TABLE (Sec INT IDENTITY(1,1), IdCuenta INT, QRetitosATM INT DEFAULT(0))
	DECLARE @fechaActual DATE=GETDATE();
	DECLARE @fechaInicio DATE=dateadd(d, @N*-1, @fechaActual)
	DECLARE @hi int, @lo int

	--Obtiene todas la cuentas de ATM en N dias
	INSERT INTO @cuentasConsulta(IdCuenta)
	SELECT M.IdCuentaAhorro
	FROM MovimientoCA M
	WHERE M.Fecha<=@fechaActual
		AND M.Fecha>=@fechaInicio
		AND M.IdTipoMovimientoCA=6

	SELECT @lo=1, @hi=MAX(Sec) FROM @cuentasConsulta

	WHILE @lo<=@hi
	BEGIN
		UPDATE @cantATM
		SET QRetitosATM=QRetitosATM+1
		FROM @cuentasConsulta C, @cantATM A
		WHERE C.IdCuenta=A.IdCuenta
			AND C.Sec=@lo
			AND EXISTS (SELECT IdCuenta FROM @cantATM WHERE Sec=@lo)

		INSERT INTO @cantATM(IdCuenta)
		SELECT C.IdCuenta
		FROM @cuentasConsulta C
		WHERE C.Sec=@lo
			 AND NOT EXISTS (SELECT IdCuenta FROM @cantATM WHERE Sec=@lo)

		SET @lo=@lo+1
	END

	INSERT INTO @cuentasConsultaFinal(IdCuenta, QRetiros, MesMas, AnoMas)
	SELECT A.IdCuenta,
		AVG(E.QOperacionesATM),
		(SELECT datepart(m, E.FechaFin) WHERE E.QOperacionesATM=MAX(E.QOperacionesATM)),
		(SELECT datepart(y, E.FechaFin) WHERE E.QOperacionesATM=MAX(E.QOperacionesATM))
	FROM @cantATM A, CuentaAhorro CA, EstadoCuenta E, TipoCuentaAhorro TCA
	WHERE A.QRetitosATM>=5
	AND A.IdCuenta=CA.ID
	AND E.IdCuentaAhorro=CA.ID
	AND CA.IdTipoCuentaAhorro=TCA.ID
	AND E.QOperacionesATM>=TCA.NumRetirosAutomaticos
	GROUP BY A.IdCuenta, E.QOperacionesATM, E.FechaFin

	SELECT * FROM @cuentasConsultaFinal

	COMMIT TRAN C2
	END TRY
	BEGIN CATCH
		IF @@tRANCOUNT>0
			ROLLBACK TRAN C2;
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
END;
GO



CREATE PROCEDURE dbo.ConsultaC(@outCodeResult int OUT )
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY

	BEGIN TRAN C3

	DECLARE @ListaBeneficiarios TABLE (Sec int identity(1,1), Nombre varchar(64), Cedula varchar(32),
		Monto money, NumeroMaxCuenta varchar(32), QCuentas int, MontoMax money)
	
	INSERT INTO @ListaBeneficiarios(
		Nombre, 
		Cedula,
		Monto, 
		QCuentas, 
		MontoMax)
	SELECT 
		P.Nombre, 
		P.ValorDocumentoIdentidad,
		(SELECT SUM(CA.Saldo*(B.Porcentaje/100)) WHERE B.IdCuentaAhorro=CA.ID),
		(SELECT COUNT(CA.NumeroCuenta) WHERE B.IdCuentaAhorro=CA.ID),
		(SELECT MAX(CA.Saldo*(B.Porcentaje/100)) WHERE B.IdCuentaAhorro=CA.ID)
	FROM Beneficiario B, Persona P, CuentaAhorro CA
	WHERE B.IdBeneficiario=P.ID
		AND B.IdCuentaAhorro=CA.ID
	GROUP BY P.Nombre, P.ValorDocumentoIdentidad, CA.Saldo,
		B.Porcentaje, CA.NumeroCuenta, B.IdCuentaAhorro, CA.ID

	UPDATE @ListaBeneficiarios
	SET 
		NumeroMaxCuenta = C.NumeroCuenta
	FROM Beneficiario B, CuentaAhorro C
	WHERE C.Saldo*(B.Porcentaje/100) = MontoMax

	SELECT * FROM @ListaBeneficiarios
	ORDER BY Monto DESC

	COMMIT TRAN C3

	END TRY
	BEGIN CATCH
		IF @@tRANCOUNT>0
			ROLLBACK TRAN C3;
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
END;
GO




-- Pruebas Bitacora
EXEC ActualizarCuentaObjetivo '1186', '2022-01-01', '2023-01-01', 'Playa', 0
EXEC ActivacionCuentaObjetivo '2222', 0

EXEC EditarBeneficiario '12738545', 'Juan', '11111111', 1, 10, '1990-10-10', 'juan@gmail.com', 88888888, 2222222
EXEC EliminarBeneficiario '179934028', 0
EXEC EliminarBeneficiario '174808854', 0

SELECT * from Evento

--Consultas
EXEC ConsultaA, 0

EXEC ConsultaB, 5, 0

EXEC ConsultaC, 0
