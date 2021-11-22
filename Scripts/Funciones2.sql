USE BANCO 
GO


CREATE PROCEDURE InsertarCuentaObjetivo(
	@NumeroCuenta varchar(32),
	@FechaInicio varchar(32),
	@FechaFin varchar(32),
	@Costo int,
	@Objetivo varchar(64),
	@Saldo int,
	@Interes int,
	@outCodeResult int OUTPUT)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		DECLARE @IdCuenta int
		SELECT @IdCuenta=C.ID
		FROM [dbo].[CuentaAhorro] C
		WHERE C.NumeroCuenta=@NumeroCuenta

		BEGIN TRANSACTION F1
			SELECT CAST(@FechaInicio AS date) AS dataconverted;
			SELECT CAST(@FechaFin AS date) AS dataconverted;

			INSERT INTO [dbo].[CuentaObjetivo](
				[FechaInicio],
				[FechaFin],
				[Costo],
				[Objetivo],
				[Saldo],
				[InteresAcumulado],
				[IdCuentaAhorro])
			SELECT
				@FechaInicio,
				@FechaFin,
				@Costo,
				@Objetivo,
				@Saldo,
				@Interes,
				@IdCuenta
		COMMIT TRANSACTION F1
	 END TRY
	 BEGIN CATCH
		IF @@tRANCOUNT>0
			ROLLBACK TRAN F1;
		--INSERT EN TABLA DE ERRORES;
		SET @outCodeResult=50005;
	 END CATCH
	 SET NOCOUNT OFF
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
		FROM [dbo].[CuentaAhorro] C
		WHERE C.NumeroCuenta=@NumeroCuenta

		BEGIN TRANSACTION F2
			SELECT CAST(@FechaInicio AS date) AS dataconverted
			SELECT CAST(@FechaFin AS date) AS dataconverted

			UPDATE [dbo].[CuentaObjetivo]
			SET
				[FechaInicio]=@FechaInicio,
				[FechaFin]=@FechaFin,
				[Objetivo]=@Objetivo
			WHERE [IdCuentaAhorro]=@IdCuenta
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
		FROM [dbo].[CuentaAhorro] C
		WHERE C.NumeroCuenta=@NumeroCuenta

		DECLARE @Valor bit
		SELECT @Valor=C.Activo
		FROM [dbo].[CuentaObjetivo] C
		WHERE C.IdCuentaAhorro=@IdCuenta

		IF  @Valor=1
		BEGIN
			SET @Valor=0
		END ELSE
		BEGIN
			SET @Valor=1
		END

		BEGIN TRANSACTION F3
			UPDATE [dbo].[CuentaObjetivo]
			SET [Activo]=@Valor
			WHERE [IdCuentaAhorro]=@IdCuenta
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

exec GetEstadosCuenta '11000001'


DROP PROCEDURE GetEstadosCuenta
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


CREATE PROCEDURE dbo.GetEstadosCuenta(@NumeroCuenta varchar(32))
AS
BEGIN

	SELECT 
		E.ID,
		E.Activo,
		E.FechaFin,
		E.FechaInicio,
		E.IdCuentaAhorro, 
		E.QOperacionesATM,
		E.QOperacionesHumano,
		E.SaldoFinal, 
		E.SaldoInicial,
		E.SaldoMinimoMes
	FROM [dbo].[EstadoCuenta] E, [dbo].[CuentaAhorro] C
	WHERE [IdCuentaAhorro]=C.ID
		AND C.NumeroCuenta=@NumeroCuenta

END;
GO