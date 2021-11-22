USE [Banco]
GO

CREATE TABLE dbo.TipoCambio(
	ID int IDENTITY(1,1) not null,
	Fecha date not null,
	CompraTC money not null,
	VentaTC money not null,
	IdMoneda int not null,

	CONSTRAINT pk_TipoCambio PRIMARY KEY (ID)
);


CREATE TABLE dbo.TipoMovimientoCA(
	ID int not null,
	Nombre varchar(64) not null,
	Operacion int not null

	CONSTRAINT pk_TipoMovimientoCA PRIMARY KEY (ID)
);


CREATE TABLE dbo.MovimientoCA(
	ID int IDENTITY(1,1) not null,
	Fecha date not null,
	Monto money not null,
	NuevoSaldo money not null,
	IdCuentaAhorro int not null,
	IdTipoMovimientoCA int not null,
	IdEstadoCuenta int not null,
	Descripcion varchar(64) not null,
	IdMoneda int not null

	CONSTRAINT pk_MovimientoCuentaAhorro PRIMARY KEY (ID)
);


CREATE TABLE dbo.EstadoCuenta(
	ID int IDENTITY(1,1) not null,
	FechaInicio date not null,
	FechaFin date not null,
	SaldoInicial money not null,
	SaldoFinal money not null,
	IdCuentaAhorro int not null,
	QOperacionesHumano int not null,
	QOperacionesATM int not null,
	Activo bit DEFAULT(1) not null,
	SaldoMinimoMes money not null,

	CONSTRAINT pk_EstadoCuenta PRIMARY KEY (ID)
);


CREATE TABLE dbo.CuentaObjetivo(
	ID int IDENTITY(1,1) not null,
	CodigoCuenta varchar(32) not null,
	FechaInicio date not null,
	FechaFin date not null,
	Costo money not null,
	Objetivo varchar(64),
	Saldo money  not null,
	InteresAcumulado float not null,
	IdCuentaAhorro int not null,
	Activo bit DEFAULT(1) not null,
	DiaAhorro int not null,
	MesesAhorrados int not null,

	CONSTRAINT pk_CuentaObjetivo PRIMARY KEY (ID)
);


CREATE TABLE dbo.TipoMovimientoCO(
	ID int not null,
	Nombre varchar(64) not null,

	CONSTRAINT pk_TipoMovimientoCO PRIMARY KEY (ID)
)


CREATE TABLE dbo.MovimientoCO(
	ID int IDENTITY(1,1) not null,
	Fecha date not null,
	Monto money not null,
	NuevoSaldo money not null,
	IdCuentaObjetivo int not null,
	IdTipoMovimientoCO int not null,

	CONSTRAINT pk_MovimientoCO PRIMARY KEY (ID)
)


CREATE TABLE dbo.MovimientoInteresCO(
	ID int IDENTITY(1,1) not null,
	Fecha date not null,
	Monto money not null,
	NuevoSaldoAcumulado money not null,
	IdCuentaObjetivo int not null,

	CONSTRAINT pk_MovimientoInteresCO PRIMARY KEY (ID)
)


CREATE TABLE dbo.TipoEvento(
	ID int not null,
	Nombre varchar(64) not null,

	CONSTRAINT pk_TipoEvento PRIMARY KEY (ID)
)


CREATE TABLE dbo.Evento(
	ID int IDENTITY(1,1) not null,
	IdUser int not null,
	IP varchar(32) not null,
	Fecha date not null,
	XMLAntes xml not null,
	XMLDespues xml not null,
	IdTipoEvento int not null,

	CONSTRAINT pk_Evento PRIMARY KEY (ID)
)


CREATE TABLE dbo.TasaInteres(
	ID int not null,
	TasaInteres float not null,

	CONSTRAINT pk_TasaInteres PRIMARY KEY (ID)
)



ALTER TABLE dbo.TipoCambio
	ADD CONSTRAINT fk_TipoCambio_Moneda FOREIGN KEY (IdMoneda) 
	REFERENCES dbo.Moneda (ID);


ALTER TABLE dbo.Moneda
	ADD CONSTRAINT fk_Moneda_TipoCambio FOREIGN KEY (IdTipoCambioFinal) 
	REFERENCES dbo.TipoCambio (ID);


ALTER TABLE dbo.MovimientoCA
	ADD CONSTRAINT fk_MovimientoCA_CuentaAhorros FOREIGN KEY (IdCuentaAhorro) 
	REFERENCES dbo.CuentaAhorro (ID);

ALTER TABLE dbo.MovimientoCA
	ADD CONSTRAINT fk_MovimientoCA_TipoMovimientoCA FOREIGN KEY (IdTipoMovimientoCA) 
	REFERENCES dbo.TipoMovimientoCA (ID);

ALTER TABLE dbo.MovimientoCA
	ADD CONSTRAINT fk_MovimientoCA_EstadoCuenta FOREIGN KEY (IdEstadoCuenta) 
	REFERENCES dbo.EstadoCuenta (ID);


ALTER TABLE dbo.EstadoCuenta
	ADD CONSTRAINT fk_EstadoCuenta_CuentaAhorro FOREIGN KEY (IdCuentaAhorro) 
	REFERENCES dbo.CuentaAhorro (ID);


ALTER TABLE dbo.CuentaObjetivo
	ADD CONSTRAINT fk_CuentaObjetivo_CuentaAhorro FOREIGN KEY (IdCuentaAhorro)
	REFERENCES dbo.CuentaAhorro (ID);




ALTER TABLE dbo.MovimientoCO
	ADD CONSTRAINT fk_MovimientoCO_CuentaObjetivo FOREIGN KEY (IdCuentaObjetivo)
	REFERENCES dbo.CuentaObjetivo(ID);


ALTER TABLE dbo.MovimientoCO
	ADD CONSTRAINT fk_MovimientoCO_TipoMovimientoCO FOREIGN KEY (IdTipoMovimientoCO)
	REFERENCES dbo.TipoMovimientoCO(ID);


ALTER TABLE dbo.MovimientoInteresCO
	ADD CONSTRAINT fk_MovimientoInteresCO_CuentaObjetivo FOREIGN KEY (IdCuentaObjetivo)
	REFERENCES dbo.CuentaObjetivo(ID);


ALTER TABLE dbo.Evento
	ADD CONSTRAINT fk_Evento_TipoEvento FOREIGN KEY (IdTipoEvento)
	REFERENCES dbo.TipoEvento(ID);
