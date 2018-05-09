/*==================================================
| Demo  : Backup Database On – Premisses no Azure  |
| Evento: DBA Brasil 3.0                           |
| Data  : 05/05/18                                 |                                                                                         |
==================================================*/	 


----------------------------------------------------------------------------------------------------------*/
/*==========================================================================================================
|                                            Criação do Banco de Dados                                     |
==========================================================================================================*/
-- Etapa 1

	CREATE DATABASE dbabr3 ON PRIMARY
		(NAME       = N'dbabr3_Data',
		 FILENAME   = N'D:\DBA Brasil_3_0\Backup_SQL_Azure\Bancos\MDF\dbabr3.mdf',
		 SIZE       = 8 MB,
		 MAXSIZE    = UNLIMITED,
		 FILEGROWTH = 16 MB),    
	
		FILEGROUP FG1 
		(NAME       = N'dbabr3_Data2',
		 FILENAME   = N'D:\DBA Brasil_3_0\Backup_SQL_Azure\Bancos\MDF\dbabr3.ndf',
		 SIZE       = 8 MB,
		 MAXSIZE    = UNLIMITED,
		 FILEGROWTH = 16 MB),	
		 
	
		FILEGROUP Documents CONTAINS FILESTREAM DEFAULT
		(NAME     = N'Documents',
		 FILENAME = N'D:\DBA Brasil_3_0\Backup_SQL_Azure\Bancos\Documents\dbabr3Documents')
		 
		LOG ON
		(NAME       = N'dbabr3_Log',
		 FILENAME   = N'D:\DBA Brasil_3_0\Backup_SQL_Azure\Bancos\LDF\dbabr3.ldf',
		 SIZE       = 8 MB,
		 MAXSIZE    = 2048 GB,
		 FILEGROWTH = 16 MB)

GO

USE dbabr3

GO

CREATE TABLE Class_Mani_Cont(

		CouterType varchar(50),
		CouterName varchar(50),
		)

-- Inserindo dados na Tabela Class_Mani_Cont, por categoria: System

GO
	
	INSERT INTO Class_Mani_Cont VALUES('System','System Calls/sec'),
									  ('System','Exception Dispatches/sec'),
								      ('System','Processor Queue Length'),	
									  ('System','Context Switches/sec')	


-- Verificando os dados inseridos do System, na Tabela Class_Mani_Cont

GO	
	SELECT *
		FROM Class_Mani_Cont
						
----------------------------------------------------------------------------------------------------------*/
/*==========================================================================================================
|                              Criação de uma credencial para o Backup DBA Brasil 3.0                      |
==========================================================================================================*/
-- Etapa 2
	
	CREATE CREDENTIAL Backup_dbabr3
	WITH IDENTITY = 'dbabrasil' 
	,SECRET = 'ZnwpCMqRxjR1/45b62hP0zP2ULS2UXmoghr3Z6zviaMqtJbyF9PEiaz5GREQV06g+UqvJDcs/oD4mKiOz39A7g=='

	drop credential Backup_dbabr3


-- Verificando se a credencial foi criada com sucesso, para isso basta executar a seguinte instrução:

	SELECT * from sys.credentials

----------------------------------------------------------------------------------------------------------*/
/*==========================================================================================================
|                                         Fazendo o Backup no Azure                                        |
==========================================================================================================*/
-- Etapa 2
	
	BACKUP DATABASE dbabr3
	TO URL = 'https://dbabrasil.blob.core.windows.net/bacckupsqlserver/dbabr3.bak'
	WITH FORMAT, COMPRESSION, 
	STATS = 10,
	CREDENTIAL ='Backup_dbabr3'
	
GO

----------------------------------------------------------------------------------------------------------*/
/*==========================================================================================================
|                                    Deletando o Banco de Dados dbabr3                                 |
==========================================================================================================*/
-- Etapa 3

	USE master

GO

	drop database dbabr3 
	
GO

----------------------------------------------------------------------------------------------------------*/
/*==========================================================================================================
|                               Fazendo o Restore do Banco de Dados dbabr3                                 |
==========================================================================================================*/
-- Etapa 4


	RESTORE DATABASE dbabr3 
	FROM URL = 'https://dbabrasil.blob.core.windows.net/bacckupsqlserver/dbabr3.bak'
	WITH REPLACE,STATS=5,
	CREDENTIAL = 'Backup_dbabr3'

----------------------------------------------------------------------------------------------------------*/
/*==========================================================================================================
|                              Tirando o Banco de Dados dbabr3 de restrictuser                             |
==========================================================================================================*/
-- Etapa 5


	ALTER DATABASE dbabr3  SET MULTI_USER

--====================================================================================================================================