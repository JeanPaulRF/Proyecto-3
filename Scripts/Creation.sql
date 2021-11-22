--BASE DE DATOS
CREATE DATABASE Banco
GO
use Banco
GO

--TABLAS
--Catalogo
CREATE TABLE dbo.TipoIdentidad(
	ID int not null,
	Nombre varchar(32) not null,
	
	CONSTRAINT pk_TipoIdentidad PRIMARY KEY (ID)
);

CREATE TABLE dbo.Parentesco(
	ID int not null,
	Nombre varchar(64) not null,
	
	CONSTRAINT pk_Parentesco PRIMARY KEY (ID)
);

CREATE TABLE dbo.TipoCuentaAhorro(
	ID int not null,
	Nombre varchar(32) not null,
	IdMoneda int not null,
	SaldoMinimo money not null,
	MultaSaldoMin money not null,
	CargoAnual int not null,
	NumRetirosHumanos int not null,
	NumRetirosAutomaticos int not null,
	ComisionHumano int not null,
	ComisionAutomatico int not null,
	Interes int not null,
	
	CONSTRAINT pk_TipoCuentaAhorro PRIMARY KEY (ID)
);

CREATE TABLE dbo.Moneda(
	ID int not null,
	Nombre varchar(16) not null,
	IdTipoCambioFinal int

	CONSTRAINT pk_Moneda PRIMARY KEY (ID)
);


--No Catalogodbo.
CREATE TABLE dbo.Persona(
	ID int IDENTITY(1,1),
	Nombre varchar(64) not null,
	ValorDocumentoIdentidad varchar(32) not null,
	IdTipoIdentidad int not null,
	FechaDeNacimiento varchar(32) not null,
	Email varchar(32) not null,
	Telefono1 int not null,
	Telefono2 int not null,
	
	CONSTRAINT pk_Persona PRIMARY KEY (ID),
);

CREATE TABLE dbo.CuentaAhorro(
	ID int IDENTITY(1,1),
	IdCliente int not null,
	NumeroCuenta varchar(32) not null,   
	Saldo money not null,
	FechaConstitucion varchar(32) not null,
	IdTipoCuentaAhorro int not null,
	
	CONSTRAINT pk_CuentaAhorro PRIMARY KEY (ID)
);


CREATE TABLE dbo.Beneficiario(
	ID int IDENTITY(1,1),
	IdCliente int not null,
	IdCuentaAhorro int not null,
	NumeroCuenta varchar(32) not null,
	Porcentaje int not null,
	IdBeneficiario int not null,
	IdParentesco int not null,
	Activo bit DEFAULT (1) not null,
	FechaDesactivacion varchar(32),

	CONSTRAINT pk_Beneficiario PRIMARY KEY (ID)
);


CREATE TABLE dbo.Usuario(
	ID int IDENTITY(1,1),
	Nombre varchar(16) not null,
	IdPersona int not null,
	Contrasena varchar(32) not null,
	Administrador bit not null,
	
	CONSTRAINT pk_Usuario PRIMARY KEY (ID)
);

CREATE TABLE dbo.UsuarioPuedeVer(
	ID int IDENTITY(1,1),
	IdCuentaAhorro int not null,
	IdPersona int not null,
	Nombre varchar(16) not null, 
	
	CONSTRAINT pk_UsuarioPuedeVer PRIMARY KEY (ID)
);


-- FKs
--TipoCuentaAhorro-Moneda
ALTER TABLE dbo.TipoCuentaAhorro 
	ADD CONSTRAINT fk_TipoCuentaAhorro_Moneda FOREIGN KEY (IdMoneda) 
	REFERENCES dbo.Moneda (ID);

-- Persona-TipoIdentidad
ALTER TABLE dbo.Persona 
	ADD CONSTRAINT fk_Persona_TipoIdentidad FOREIGN KEY (IdTipoIdentidad) 
	REFERENCES dbo.TipoIdentidad (ID);

-- CuentaAhorro-TipoCuentaAhorro
ALTER TABLE dbo.CuentaAhorro 
	ADD CONSTRAINT fk_CuentaAhorro_TipoCuentaAhorro FOREIGN KEY (IdTipoCuentaAhorro) 
	REFERENCES dbo.TipoCuentaAhorro (ID);
-- CuentaAhorro-Persona
ALTER TABLE dbo.CuentaAhorro 
	ADD CONSTRAINT fk_CuentaAhorro_Persona FOREIGN KEY (IdCliente) 
	REFERENCES dbo.Persona (ID); 


-- Beneficiario-Persona
ALTER TABLE dbo.Beneficiario 
	ADD CONSTRAINT fk_Beneficiario_Persona FOREIGN KEY (IdCliente) 
	REFERENCES dbo.Persona (ID);
-- Beneficiario-CuentaAhorros
ALTER TABLE dbo.Beneficiario 
	ADD CONSTRAINT fk_Beneficiario_CuentaAhorro FOREIGN KEY (IdCuentaAhorro) 
	REFERENCES CuentaAhorro (ID);
-- Beneficiario-Parentesco
ALTER TABLE dbo.Beneficiario 
	ADD CONSTRAINT fk_CuentaAhorro_Beneficiario FOREIGN KEY (IdParentesco) 
	REFERENCES dbo.Parentesco (ID);


-- UsuarioPuedeVer-Usuario
ALTER TABLE dbo.UsuarioPuedeVer 
	ADD CONSTRAINT fk_UsuarioPuedeVer_Usuario FOREIGN KEY (IdPersona) 
	REFERENCES dbo.Usuario (ID);
-- UsuarioPuedeVer-CuentaAhorro
ALTER TABLE dbo.UsuarioPuedeVer 
	ADD CONSTRAINT fk_UsuarioPuedeVer_CuentaAhorros FOREIGN KEY (IdCuentaAhorro) 
	REFERENCES dbo.CuentaAhorro (ID);