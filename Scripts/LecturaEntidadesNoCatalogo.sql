USE [Banco]
GO

DECLARE @xmlData XML

DECLARE @CurrentTime DATE=GETDATE();

SET @xmlData = 
		(SELECT *
		FROM OPENROWSET(BULK 'C:\Users\Jota\Desktop\BSL2021\Scripts\DatosTarea1.xml', SINGLE_BLOB) 
		AS xmlData);


--Persona
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
	T.Item.value('@FechaNacimiento','VARCHAR(32)'),
	T.Item.value('@Email','VARCHAR(64)'),
	T.Item.value('@Telefono1','VARCHAR(16)'),
	T.Item.value('@Telefono2','VARCHAR(16)')
FROM @xmlData.nodes('Datos/Personas/Persona') as T(Item)


--Usuario
DECLARE @TempUser TABLE
	(Nombre varchar(16),
	Contrasena varchar(32),
	ValorDocumentoIdentidad varchar(32),
	Adim bit)

INSERT INTO @TempUser(
	Nombre,
	Contrasena,
	ValorDocumentoIdentidad,
	Adim)
SELECT 
	T.Item.value('@Usuario', 'VARCHAR(16)'),
	T.Item.value('@Pass', 'VARCHAR(32)'),
	T.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(32)'),
	T.Item.value('@EsAdministrador', 'BIT')
FROM @xmlData.nodes('Datos/Usuarios/Usuario') as T(Item)

INSERT INTO [dbo].[Usuario](
	[Nombre],
	[Contrasena],
	[IdPersona],
	[Administrador])
SELECT 
	T.Nombre,
	T.Contrasena,
	P.ID,
	T.Adim
FROM [dbo].[Persona] P, @TempUser T
WHERE P.ValorDocumentoIdentidad=T.ValorDocumentoIdentidad


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
	TipoCuenta
	)
SELECT T.Item.value('@NumeroCuenta','VARCHAR(32)'),
	T.Item.value('@Saldo','MONEY'),
	T.Item.value('@FechaCreacion','VARCHAR(32)'),
	T.Item.value('@ValorDocumentoIdentidadDelCliente','VARCHAR(32)'),
	T.Item.value('@TipoCuentaId','INT')
FROM @xmlData.nodes('Datos/Cuentas/Cuenta') as T(Item)

-- Mapeo @TempCuentas-CuentaAhorro
INSERT INTO [dbo].[CuentaAhorro](
	[IdCliente], 
	[NumeroCuenta], 
	[Saldo], 
	[FechaConstitucion],
	[IdTipoCuentaAhorro]
	)
SELECT 
	P.ID,
	C.NumeroCuenta,
	C.Saldo,
	C.Fecha,
	C.TipoCuenta
FROM @TempCuentas C, [dbo].[Persona] P 
WHERE C.IdentidadCliente=P.[ValorDocumentoIdentidad]


--Beneficiario
DECLARE @TempBeneficiario TABLE
	(NumeroCuenta varchar(32),
	ValorDocumentoIdentidadBeneficiario varchar(32),
	ParentezcoId INT,
	Porcentaje int)

INSERT INTO @TempBeneficiario(
	NumeroCuenta,
	ValorDocumentoIdentidadBeneficiario,
	ParentezcoId,
	Porcentaje
	)
SELECT T.Item.value('@NumeroCuenta','VARCHAR(32)'),
	T.Item.value('@ValorDocumentoIdentidadBeneficiario','VARCHAR(32)'),
	T.Item.value('@ParentezcoId','INT'),
	T.Item.value('@Porcentaje','INT')
FROM @xmlData.nodes('Datos/Beneficiarios/Beneficiario') as T(Item)


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


--UsuarioPuedeVer
DECLARE @TempUsuario TABLE
	(Usuario varchar(16),
	NumeroCuenta varchar(32))

INSERT INTO @TempUsuario(
	Usuario,
	NumeroCuenta
	)
SELECT T.Item.value('@Usuario','VARCHAR(16)'),
	T.Item.value('@NumeroCuenta','VARCHAR(32)')
FROM @xmlData.nodes('Datos/Usuarios_Ver/UsuarioPuedeVer') as T(Item)

-- Mapeo @TempUsuario-UsuarioPuedeVer
INSERT INTO [dbo].[UsuarioPuedeVer](
	[IdCuentaAhorro],
	[IdPersona],
	[Nombre]
	)
SELECT 
	C.ID,
	A.ID,
	A.Nombre
FROM @TempUsuario U, [dbo].[Usuario] A, [dbo].[CuentaAhorro] C
WHERE A.Nombre=U.Usuario AND U.NumeroCuenta=C.NumeroCuenta 