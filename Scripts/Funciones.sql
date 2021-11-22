USE [Banco]
GO


--FUNCIONES BASICAS DE BENEFICIARIO
CREATE PROCEDURE dbo.InsertarBeneficiario (
	@NumeroCuenta varchar(32),
	@Identificacion varchar(32),
	@Parentesco int, 
	@Porcentaje int)
AS
BEGIN
	IF EXISTS (SELECT * FROM [dbo].[Persona] WHERE [ValorDocumentoIdentidad]=@Identificacion)
		BEGIN

		-- Mapeo @@TempBeneficiario-Beneficiario
		INSERT INTO [dbo].[Beneficiario](
			[IdCliente], 
			[IdCuentaAhorro], 
			[NumeroCuenta], 
			[Porcentaje],
			[IdBeneficiario],
			[IdParentesco])
		SELECT C.IdCliente,
			C.ID,
			C.NumeroCuenta,
			@Porcentaje,
			P.ID,
			@Parentesco
		FROM [dbo].[CuentaAhorro] C, [dbo].[Persona] P
		WHERE @NumeroCuenta=C.NumeroCuenta	
			AND @Identificacion=P.ValorDocumentoIdentidad

		END

	ELSE 
		BEGIN

		DECLARE @vardate varchar(100)='1901-01-01'
		SELECT CAST(@vardate AS date) AS dataconverted;

		INSERT INTO [dbo].[Persona](
			[Nombre],
			[ValorDocumentoIdentidad],
			[IdTipoIdentidad],
			[FechaDeNacimiento],
			[Email],
			[Telefono1],
			[Telefono2])
		SELECT 
			'No conocido',					
			@Identificacion,								
			1,							
			@vardate,
			'na@na.com',
			'00000000',					
			'00000000'

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
			@Porcentaje,
			P.ID,
			@Parentesco
		FROM [dbo].[CuentaAhorro] C, [dbo].[Persona] P
		WHERE @NumeroCuenta=C.NumeroCuenta	
			AND @Identificacion=P.ValorDocumentoIdentidad

		END
END;
GO

CREATE PROCEDURE dbo.EditarBeneficiario (
	@IdentificacionAntigua varchar(32),
	@Nombre varchar(64),
	@Identificacion varchar(32),
	@Parentesco int, 
	@Porcentaje int,
	@FechaNacimiento varchar(32),
	@Email varchar(32),
	@Telefono1 int,
	@Telefono2 int)
AS
BEGIN
	SELECT CAST(@FechaNacimiento AS date) AS dataconverted;

	DECLARE @IdPersona int;
	SELECT @IdPersona = P.ID
	FROM [dbo].[Persona] P
	WHERE P.ValorDocumentoIdentidad=@IdentificacionAntigua;

	UPDATE [dbo].[Persona]
	SET [Nombre]=@Nombre,
		[ValorDocumentoIdentidad]=@Identificacion,
		[FechaDeNacimiento]=@FechaNacimiento,
		[Email]=@Email,
		[Telefono1]=@Telefono1,
		[Telefono2]=@Telefono2
	WHERE [ID]=@IdPersona

	UPDATE [dbo].[Beneficiario]
	SET [Porcentaje]=@Porcentaje,
		[IdParentesco]=@Parentesco
	WHERE [IdBeneficiario]=@IdPersona

	SELECT * FROM [dbo].[Persona] WHERE ID=@IdPersona
	SELECT * FROM [dbo].[Beneficiario] WHERE IdBeneficiario=@IdPersona
END;
GO
--USE BANCO
--GO
--EXEC dbo.EditarBeneficiario '12738545', 'OSVALDO', '777', 1, 100, '2000-01-01', 'HI', '0','0'


CREATE PROCEDURE dbo.EliminarBeneficiario (@Identificacion varchar(32), @value int)
AS
BEGIN
	DECLARE @CurrentTime DATE=GETDATE();

	DECLARE @IdBen int;
	SELECT @IdBen=P.ID
	FROM [dbo].[Persona] P
	WHERE P.ValorDocumentoIdentidad = @Identificacion

	UPDATE [dbo].[Beneficiario]
	SET [Activo]=@value,
		[Porcentaje]=@value,
		[FechaDesactivacion]=@CurrentTime
	WHERE [IdBeneficiario]=@IdBen

	SELECT * FROM Beneficiario
END;
GO


-- SP BENEFICIARIO
CREATE PROCEDURE dbo.GetTotalBeneficiarios (@Identificacion varchar(32))
AS
BEGIN
	DECLARE @IdCliente int;
	SELECT @IdCliente = P.ID
	FROM dbo.Persona P
	WHERE P.ValorDocumentoIdentidad=@Identificacion;

	SELECT COUNT(*) FROM [dbo].[Beneficiario] 
	WHERE [IdCliente]=@IdCliente
	AND [Activo]=1
END;
GO


CREATE PROCEDURE dbo.GetBeneficiariosActivosDeCliente (@Identificacion varchar(32))
AS
BEGIN

	DECLARE @IdCliente int;
	SELECT @IdCliente = P.ID
	FROM [dbo].[Persona] P
	WHERE P.ValorDocumentoIdentidad=@Identificacion;

	DECLARE @TempBeneficiario TABLE(
		NumeroCuenta varchar(32),
		Nombre varchar(64),
		Identificacion varchar(32), 
		Parentesco int, 
		Porcentaje int,
		FechaNacimiento varchar(32),
		Email varchar(32),
		Telefono1 int,
		Telefono2 int,
		Activo bit)

	INSERT INTO @TempBeneficiario(
		Identificacion,
		NumeroCuenta,
		Parentesco, 
		Porcentaje,
		Activo)
	SELECT
		P.ValorDocumentoIdentidad,
		B.NumeroCuenta,
		B.IdParentesco,
		B.Porcentaje,
		B.Activo
	FROM [dbo].[Beneficiario] B, [dbo].[Persona] P
	WHERE B.IdCliente=@IdCliente AND Activo=1
		AND B.IdBeneficiario=P.ID

	SELECT
		T.Identificacion,
		T.NumeroCuenta,
		T.Parentesco, 
		T.Porcentaje,
		P.[Nombre],
		P.[FechaDeNacimiento],
		P.[Email],
		P.[Telefono1],
		P.[Telefono2],
		T.Activo
	FROM @TempBeneficiario T INNER JOIN [dbo].[Persona] P ON T.Identificacion=P.[ValorDocumentoIdentidad]
END;
GO



CREATE PROCEDURE dbo.GetBeneficiariosDeCliente (@Identificacion varchar(32))
AS
BEGIN

	DECLARE @IdCliente int;
	SELECT @IdCliente = P.ID
	FROM [dbo].[Persona] P
	WHERE P.ValorDocumentoIdentidad=@Identificacion;

	DECLARE @TempBeneficiario TABLE(
		NumeroCuenta varchar(32),
		Nombre varchar(64),
		Identificacion varchar(32), 
		Parentesco int, 
		Porcentaje int,
		FechaNacimiento varchar(32),
		Email varchar(32),
		Telefono1 int,
		Telefono2 int,
		Activo bit
	)
	INSERT INTO @TempBeneficiario(
		Identificacion,
		NumeroCuenta,
		Parentesco, 
		Porcentaje,
		Activo
	)
	SELECT
		P.ValorDocumentoIdentidad,
		B.NumeroCuenta,
		B.IdParentesco,
		B.Porcentaje,
		B.Activo
	FROM [dbo].[Beneficiario] B, [dbo].[Persona] P
	WHERE B.IdCliente=@IdCliente
		AND B.IdBeneficiario=P.ID
	
	SELECT
		T.Identificacion,
		T.NumeroCuenta,
		T.Parentesco, 
		T.Porcentaje,
		P.[Nombre],
		P.[FechaDeNacimiento],
		P.[Email],
		P.[Telefono1],
		P.[Telefono2],
		T.Activo
	FROM @TempBeneficiario T INNER JOIN [dbo].[Persona] P ON T.Identificacion=P.[ValorDocumentoIdentidad]
END;
GO	


CREATE PROCEDURE dbo.GetBeneficiario (@Identificacion varchar(32))
AS
BEGIN
	DECLARE @TempBeneficiario TABLE(
		NumeroCuenta varchar(32),
		Nombre varchar(64),
		Identificacion varchar(32), 
		Parentesco int, 
		Porcentaje int,
		FechaNacimiento varchar(32),
		Email varchar(32),
		Telefono1 int,
		Telefono2 int,
		Activo bit
	)
	INSERT INTO @TempBeneficiario(
		Identificacion,
		NumeroCuenta,
		Parentesco, 
		Porcentaje,
		Activo
	)
	SELECT
		@Identificacion,
		B.NumeroCuenta,
		B.IdParentesco,
		B.Porcentaje,
		B.Activo
	FROM [dbo].[Beneficiario] B, [dbo].[Persona] P
	WHERE P.ValorDocumentoIdentidad=@Identificacion
		AND B.IdBeneficiario=P.ID
	
	SELECT
		T.Identificacion,
		T.NumeroCuenta,
		T.Parentesco, 
		T.Porcentaje,
		P.[Nombre],
		P.[FechaDeNacimiento],
		P.[Email],
		P.[Telefono1],
		P.[Telefono2],
		T.Activo
	FROM @TempBeneficiario T INNER JOIN [dbo].[Persona] P ON T.Identificacion=P.[ValorDocumentoIdentidad]
END;
GO	


CREATE PROCEDURE dbo.GetTodosBeneficiarios
AS
BEGIN
	DECLARE @TempBeneficiario TABLE(
		NumeroCuenta varchar(32),
		Nombre varchar(64),
		Identificacion varchar(32), 
		Parentesco int, 
		Porcentaje int,
		FechaNacimiento varchar(32),
		Email varchar(32),
		Telefono1 int,
		Telefono2 int,
		Activo bit
	)
	INSERT INTO @TempBeneficiario(
		Identificacion,
		NumeroCuenta,
		Parentesco, 
		Porcentaje,
		Activo
	)
	SELECT
		P.ValorDocumentoIdentidad,
		B.NumeroCuenta,
		B.IdParentesco,
		B.Porcentaje,
		B.Activo
	FROM [dbo].[Beneficiario] B, [dbo].[Persona] P
	WHERE P.ID=B.IdBeneficiario

	
	SELECT
		T.Identificacion,
		T.NumeroCuenta,
		T.Parentesco, 
		T.Porcentaje,
		P.[Nombre],
		P.[FechaDeNacimiento],
		P.[Email],
		P.[Telefono1],
		P.[Telefono2],
		T.Activo
	FROM @TempBeneficiario T INNER JOIN [dbo].[Persona] P ON T.Identificacion=P.[ValorDocumentoIdentidad]
END;
GO




-- CLIENTES

CREATE PROCEDURE dbo.GetCliente(@Identificacion varchar(32))
AS
BEGIN
	SELECT * FROM [dbo].[Persona] WHERE [ValorDocumentoIdentidad]=@Identificacion
END;
GO


CREATE PROCEDURE dbo.GetTodosClientes
AS
BEGIN
	SELECT * FROM [dbo].[Persona]
END;
GO


-- CUENTAS

CREATE PROCEDURE dbo.GetCuenta(@NumeroCuenta varchar(32))
AS
BEGIN
	SELECT * FROM [dbo].[CuentaAhorro] WHERE [NumeroCuenta]=@NumeroCuenta
END;
GO



CREATE PROCEDURE dbo.GetCuentasDeCliente(@Identificacion varchar(32))
AS
BEGIN
	DECLARE @IdCliente int;
	SET @IdCliente = 
	(SELECT P.ID
	FROM [dbo].[Persona] P
	WHERE P.ValorDocumentoIdentidad=@Identificacion)
	
	SELECT 
		P.ValorDocumentoIdentidad as Identificacion,
		C.NumeroCuenta as NumeroCuenta,
		C.FechaConstitucion as FechaConstitucion,
		C.IdTipoCuentaAhorro as TipoCuentaAhorro
	FROM [dbo].[CuentaAhorro] C, [dbo].[Persona] P
	WHERE P.ID=@IdCliente AND C.IdCliente=@IdCliente
END;
GO



CREATE PROCEDURE dbo.GetTodasCuentas
AS
BEGIN
	SELECT * FROM [dbo].[CuentaAhorro]
END;
GO


-- USUARIOS

CREATE PROCEDURE dbo.GetTodosUsuarios
AS
BEGIN
	SELECT * FROM dbo.Usuario;
END;
GO

CREATE PROCEDURE dbo.GetUser (@Identificacion varchar(32))
AS
BEGIN 
	SELECT * 
	FROM [dbo].[Usuario] U, [dbo].[Persona] P
	WHERE P.ValorDocumentoIdentidad=@Identificacion
		AND P.ID=U.IdPersona
END;
GO



CREATE PROCEDURE dbo.GetUsuariosPuedeVer(@Usuario varchar(16))
AS
BEGIN
	SELECT C.[NumeroCuenta] 
	FROM [dbo].[UsuarioPuedeVer] U, [dbo].[CuentaAhorro] C
	WHERE U.IdCuentaAhorro=C.ID
END;
GO


-- PORCENTAJES

CREATE PROCEDURE dbo.GetTotalPorcentajes (@Identificacion varchar(32))
AS
BEGIN
		DECLARE @IdCliente int;
		SELECT @IdCliente = P.ID
		FROM [dbo].[Persona] P
		WHERE P.ValorDocumentoIdentidad=@Identificacion;

	SELECT SUM ([Porcentaje]) FROM [dbo].[Beneficiario] WHERE IdCliente=@IdCliente
END;
GO


-- PARENTESCOS

CREATE PROCEDURE dbo.GetTodosParentescos
AS
BEGIN
	SELECT * FROM [dbo].[Parentesco]
END;
GO


--VALIDACION

CREATE PROCEDURE dbo.ValidarUsuarioContrasena(@Usuario varchar(16), @Pass varchar(32))
AS
BEGIN
	DECLARE @Tabla TABLE (Resultado int, userId VARCHAR(32))

	IF EXISTS (SELECT * FROM [dbo].[Usuario] WHERE @Usuario=Nombre)
		IF EXISTS (SELECT * FROM [dbo].[Usuario] WHERE @Pass=Contrasena)
		BEGIN
			INSERT INTO @Tabla(Resultado,userId) 
			SELECT 
			1,
			P.ValorDocumentoIdentidad 
			FROM [dbo].[Usuario] U, [dbo].[Persona] P
			WHERE @Pass=Contrasena AND U.IdPersona=P.ID
		END
		ELSE
			INSERT INTO @Tabla(Resultado) SELECT 0
	ELSE
		INSERT INTO @Tabla(Resultado) SELECT 0
	
	SELECT * FROM @Tabla
END;
GO

EXEC ValidarUsuarioContrasena 'jaguero','LaFacil'
EXEC GetUser '117370445'

exec GetCuentasDeCliente '117370445'

DROP PROCEDURE GetCuentasDeCliente 



DROP PROCEDURE GetUser 
CREATE PROCEDURE dbo.GetUser (@Identificacion varchar(32))
AS
BEGIN 
	SELECT 
		U.ID,
		U.Administrador,
		U.Contrasena,
		U.IdPersona,
		U.Nombre
	FROM [dbo].[Usuario] U, [dbo].[Persona] P
	WHERE P.ValorDocumentoIdentidad=@Identificacion
		AND P.ID=U.IdPersona
END;
GO

CREATE PROCEDURE dbo.GetCuentasDeCliente(@Identificacion varchar(32))
AS
BEGIN
	SELECT 
		P.ValorDocumentoIdentidad as Identificacion,
		C.NumeroCuenta as NumeroCuenta,
		C.FechaConstitucion as FechaConstitucion,
		C.IdTipoCuentaAhorro as TipoCuentaAhorro
	FROM [dbo].[CuentaAhorro] C, [dbo].[Persona] P
	WHERE P.ValorDocumentoIdentidad=@Identificacion AND C.IdCliente=P.ID
END;
GO