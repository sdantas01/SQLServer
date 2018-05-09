/*==========================================================================================================
| Demo: Monitorando os Recursos e Processos do Servidor, com o Power BI                                    |
| Evento: DBA Brasil 3.0                                                                                       |
| Data  : 05/05/2018                                                                                        |
==========================================================================================================*/	 
------------------------------------------------------------------------------------------------------------
/*==========================================================================================================
|                                         Rotina Perfom Contadores                                          |
===========================================================================================================*/
	
/*====================================================
|  Etapa 1 - Configuração dos Contadores no Perfmon  |
====================================================*/

-- Principais contadores - Blog Catae:
-- System, Processor, Network Interface, Memory, LogicalDisk

/* System:
			System Calls/sec,
			System Calls/sec
			Exception Dispatches/sec
			Processor Queue Length
			Context Switches/sec

   Processor:
		
			% Processor Time
            % Privileged Time

	Network Interface
			Bytes Received/sec
			Bytes Sent/sec
			Bytes Total/sec

	Memory
			Pool Paged Bytes
			Pool Nonpaged Bytes
			% Committed Bytes In Use
			Available MBytes
			Free System Page Table Entries
			Committed Bytes
		
	LogicalDisk	
				Disk Reads/sec
				Disk Read Bytes/sec
				Avg. Disk sec/Read
				Disk Writes/sec
				Current Disk Queue Length
				Avg. Disk sec/Write
				Disk Bytes/sec
				Disk Write Bytes/sec
				Disk Transfers/sec
				Avg. Disk sec/Transfer		
*/	
----------------------------------------------------------------------------------------------------------*/
/*==========================================================================================================
|                                            Criação do Banco de Dados                                     |
==========================================================================================================*/
-- Etapa 2

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

------------------------------------------------------------------------------------------------------------
/*==========================================================================================================
|                                             Rotina de Relog                                              |     |
==========================================================================================================*/
-- Etapa 3 

-- Com a rotina do Relog realizada, a mesma irá criar 3 tabelas no banco de dados Sat618.
-- CounterData - guarda as informações dos contadores do perfmon
-- CounterDetails - guarda as informações coletadas pelos contadores do perfmon
-- DisplayToID - guarda a hora que os dados são coletados

-- Visualizando os dados importados para as 3 tabelas, pelo Relog:

USE dbabr3

GO
	SELECT TOP 5 *FROM [dbo].[CounterData]
	SELECT TOP 5 *FROM [dbo].[CounterDetails]
	SELECT TOP 5 *FROM [dbo].[DisplayToID]

--==========================================================================================================

	SELECT *FROM sys.dm_os_performance_counters

	SELECT *FROM sys.tables

--==========================================================================================================
/*-------------------------------------------
| Etapa 4 - Criação da Tabela Manipula_Cont |
===========================================*/
-- Essa tabela irá receber os dados contidos nas 3 tabelas geradas pelo relog, unificando os dados em uma
-- tabela somente.

	CREATE TABLE [dbo].[Manipula_Cont](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Data] [datetime] NULL,
	[Servidor] [varchar](35) NOT NULL,
	[CouterName] [varchar](35) NOT NULL,
	[Media] [float] NOT NULL,
	[Total] [float] NOT NULL,
	PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, 
 ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

-- Visualizando a Tabela Manipula_Cont criada, a mesma está vazia. 

	SELECT *FROM Manipula_Cont

--==========================================================================================================

/*================================================================================================
| Etapa 5 - Inserindo os Dados das Tabelas: CounterData e CounterDetails na Tabela Manipula_Cont |
================================================================================================*/

-- Essa etapa, pega os dados contindos nas tabelas CounterData e CounterDetails e insere na Manipula_Cont,
-- dessa forma trabalhamos com os dados em uma tabela somente.

	INSERT Manipula_Cont(Servidor,CouterName,Data,Media,Total)
		SELECT MachineName,
		       CounterName,
			   DATEADD(MINUTE, CAST(SUBSTRING(CounterDateTime, 12, 2) AS INT) * 60 + CAST(SUBSTRING(CounterDateTime, 15, 2) AS INT), CAST(CAST(CONVERT(VARCHAR(10), CounterDateTime) AS DATE) AS DATETIME)) AS [Data],
			  (SUM(CounterValue)/2) Media,
			    SUM(CounterValue) Total
				FROM CounterData C1 
		JOIN dbo.CounterDetails C2 on  C2.CounterID = C1.CounterID
	    -- And CounterName = % Processor Time'
		GROUP BY DATEADD(MINUTE, CAST(SUBSTRING(CounterDateTime, 12, 2) AS INT) * 60 + CAST(SUBSTRING(CounterDateTime, 15, 2) AS INT), CAST(CAST(CONVERT(VARCHAR(10), CounterDateTime) AS DATE) AS DATETIME)),
		         CounterName, MachineName,ObjectName
		ORDER BY 1 ASC

-- Vizualizando os dados inseridos na Tabela Manipula_Cont

	SELECT *FROM Manipula_Cont


/*===================================================================
 Etapa 6 - Criaando uma Tabela com as categorias dos Contadores   |
===================================================================*/

-- Essa tabela irá fazer um JOIN com a Tabela Manipula_Cont, e trazer os contadores por categoria


	CREATE TABLE Class_Mani_Cont(

		CouterType varchar(50),
		CouterName varchar(50),
		)

-- Inserindo dados na Tabela Class_Mani_Cont, por categoria: System
	
	INSERT INTO Class_Mani_Cont VALUES('System','System Calls/sec'),
									  ('System','Exception Dispatches/sec'),
								      ('System','Processor Queue Length'),	
									  ('System','Context Switches/sec')	


-- Verificando os dados inseridos do System, na Tabela Class_Mani_Cont
	
	SELECT *
		FROM Class_Mani_Cont

			
-- Inserindo dados na Tabela Class_Mani_Cont, por categoria: Processor
	
	INSERT INTO Class_Mani_Cont VALUES('Processor','% Processor Time'),	
								      ('Processor','% Privileged Time')	 		
			

-- Verificando os dados inseridos do Processor na Tabela Class_Mani_Cont
	
	SELECT *
		FROM Class_Mani_Cont


-- Inserindo dados na Tabela Class_Mani_Cont, por categoria: Network Interface
	
	INSERT INTO Class_Mani_Cont VALUES('Network Interface','Bytes Received/sec'),	
								      ('Network Interface','Bytes Sent/sec'),
									  ('Network Interface','Bytes Total/sec')		 		
			

-- Verificando os dados inseridos do Network Interface na Tabela Class_Mani_Cont
	
	SELECT *
		FROM Class_Mani_Cont


-- Inserindo dados na Tabela Class_Mani_Cont, por categoria: Memory
	
	INSERT INTO Class_Mani_Cont VALUES('Memory','Pool Paged Bytes'),	
								      ('Memory','Pool Nonpaged Bytes'),
									  ('Memory','% Committed Bytes In Use'),		 		
									  ('Memory','% Available MBytes'),	
									  ('Memory','Free System Page Table Entries'),	
									  ('Memory','Committed Bytes')	
			
-- Verificando os dados inseridos do Memory na Tabela Class_Mani_Cont
	
	SELECT *
		FROM Class_Mani_Cont		
			
		
-- Inserindo dados na Tabela Class_Mani_Cont, por categoria: LogicalDisk	
	
	INSERT INTO Class_Mani_Cont VALUES('LogicalDisk','Disk Reads/sec'),	
								      ('LogicalDisk','Disk Read Bytes/sec'),
									  ('LogicalDisk','Avg. Disk sec/Read'),		 		
									  ('LogicalDisk','Disk Writes/sec'),	
									  ('LogicalDisk','Current Disk Queue Length'),	
									  ('LogicalDisk','Avg. Disk sec/Write'),
									  ('LogicalDisk','Disk Bytes/sec'),	
									  ('LogicalDisk','Disk Write Bytes/sec'),
									  ('LogicalDisk','Disk Transfers/sec'),
								      ('LogicalDisk','Avg. Disk sec/Transfer')
							
-- Verificando os dados inseridos do LogicalDisk na Tabela Class_Mani_Cont
	
	SELECT *
		FROM Class_Mani_Cont		
--==========================================================================================================
/*==========================================================================
 Etapa 7 - JOIN da Tabela Manipula_Cont com a Tabela Class_Manipula_Cont   |
==========================================================================*/

-- Essa será a consulta que será usada no Power BI, para a criação do Dashboard. 	

	SELECT M.Data,
	   C.CouterType,
	   M.CouterName, 
	   M.Media 
	FROM Manipula_Cont M
	JOIN Class_Mani_Cont C ON C.CouterName = M.CouterName
	group by M.Data,
	     C.CouterType,
	     M.CouterName, 
	     M.Media 
	ORDER BY 1,2 ASC

--============================================================================================================================================================================================================================

