-- project 3 main sql script

/* 
Step1: CREATE THE DATABASE
Instructions: run only lines 10 and 11 using the master databse 
*/

CREATE DATABASE [ClassSchedule_9:15_Group1];
GO

/*
Step2: Create the Schemas & run all remaining code & procedures  
Instructions: Run all remaining code under the [ClassSchedule_9:15_Group1] database
*/


--------------------- CREATE SCHEMAS -------------------------

DROP SCHEMA IF EXISTS [DbSecurity]; 
GO
CREATE SCHEMA [DbSecurity];
GO

DROP SCHEMA IF EXISTS [Process]; 
GO
CREATE SCHEMA [Process];
GO

DROP SCHEMA IF EXISTS [PkSequence]; 
GO
CREATE SCHEMA [PkSequence];
GO

DROP SCHEMA IF EXISTS [Project3];
GO
CREATE SCHEMA [Project3];
GO

DROP SCHEMA IF EXISTS [G9_1];
GO
CREATE SCHEMA [G9_1];
GO

------------------------- CREATE SEQUENCES ----------------------------


-- for automatically assigning keys in [DbSecurity].[UserAuthorization]
-- Aleks
CREATE SEQUENCE [PkSequence].[UserAuthorizationSequenceObject] 
 AS [int]
 START WITH 1
 INCREMENT BY 1
 MINVALUE 1
 MAXVALUE 2147483647
GO

-- for replacing identity key in [Process].[WorkflowSteps]
CREATE SEQUENCE [PkSequence].[WorkFlowStepsSequenceObject] 
 AS [int]
 START WITH 1
 INCREMENT BY 1
 MINVALUE 1
 MAXVALUE 2147483647
GO


-- add more sequences as needed



------------------------- CREATE TABLES ---------------------------


-- UserAuthorization Table -- 

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
DROP TABLE IF EXISTS [DbSecurity].[UserAuthorization]
GO
CREATE TABLE [DbSecurity].[UserAuthorization]
(
    [UserAuthorizationKey] [int] NOT NULL,
    [ClassTime] [nchar](5) NOT NULL,
    [IndividualProject] [nvarchar](60) NULL,
    [GroupMemberLastName] [nvarchar](35) NOT NULL,
    [GroupMemberFirstName] [nvarchar](25) NOT NULL,
    [GroupName] [nvarchar](20) NOT NULL,
    [DateAdded] [datetime2](7) NULL,
    PRIMARY KEY CLUSTERED 
(
	[UserAuthorizationKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


/*

Table: Process.[WorkflowSteps]

Description:
This table is used for auditing and tracking the execution of various workflow steps within the system. 
It records key information about each workflow step, including a description, the number of rows affected, 
the start and end times of the step, and the user who executed the step.

*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
DROP TABLE IF EXISTS [Process].[WorkflowSteps]
GO
CREATE TABLE [Process].[WorkflowSteps]
(
    [WorkFlowStepKey] [int] NOT NULL,
    [WorkFlowStepDescription] [nvarchar](100) NOT NULL,
    [WorkFlowStepTableRowCount] [int] NULL,
    [StartingDateTime] [datetime2](7) NULL,
    [EndingDateTime] [datetime2](7) NULL,
    [QueryTime (ms)] [bigint] NULL, 
    [Class Time] [char](5) NULL,
    [UserAuthorizationKey] [int] NOT NULL,
    PRIMARY KEY CLUSTERED 
(
	[WorkFlowStepKey] ASC
)WITH (PAD_INDEX = OFF, 
STATISTICS_NORECOMPUTE = OFF, 
IGNORE_DUP_KEY = OFF, 
ALLOW_ROW_LOCKS = ON, 
ALLOW_PAGE_LOCKS = ON, 
OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO








--------------------- Alter Tables To Update Defaults/Constraints -------------------


-- Aleks
ALTER TABLE [DbSecurity].[UserAuthorization] ADD  DEFAULT (NEXT VALUE FOR PkSequence.[UserAuthorizationSequenceObject]) FOR [UserAuthorizationKey]
GO
ALTER TABLE [DbSecurity].[UserAuthorization] ADD  DEFAULT ('9:15') FOR [ClassTime]
GO
ALTER TABLE [DbSecurity].[UserAuthorization] ADD  DEFAULT ('PROJECT 3 CLASS SCHEDULE SCHEMA') FOR [IndividualProject]
GO
ALTER TABLE [DbSecurity].[UserAuthorization] ADD  DEFAULT ('GROUP 1') FOR [GroupName]
GO
ALTER TABLE [DbSecurity].[UserAuthorization] ADD  DEFAULT (sysdatetime()) FOR [DateAdded]
GO
ALTER TABLE [Process].[WorkflowSteps] ADD  DEFAULT (NEXT VALUE FOR PkSequence.[WorkFlowStepsSequenceObject]) FOR [WorkFlowStepKey]
GO
ALTER TABLE [Process].[WorkflowSteps] ADD  DEFAULT ((0)) FOR [WorkFlowStepTableRowCount]
GO
ALTER TABLE [Process].[WorkflowSteps] ADD  DEFAULT (sysdatetime()) FOR [StartingDateTime]
GO
ALTER TABLE [Process].[WorkflowSteps] ADD  DEFAULT (sysdatetime()) FOR [EndingDateTime]
GO
ALTER TABLE [Process].[WorkflowSteps] ADD  DEFAULT ('9:15') FOR [Class Time]
GO



-- add check constraints in the following format: 
-- Aleks
ALTER TABLE [Process].[WorkflowSteps]  WITH CHECK ADD  CONSTRAINT [FK_WorkFlowSteps_UserAuthorization] FOREIGN KEY([UserAuthorizationKey])
REFERENCES [DbSecurity].[UserAuthorization] ([UserAuthorizationKey])
GO
ALTER TABLE [Process].[WorkflowSteps] CHECK CONSTRAINT [FK_WorkFlowSteps_UserAuthorization]
GO





------------------------------- CREATE TABLE VALUED FUNCTIONS ----------------------------








--------------------------------- Create Stored Procedures -------------------------------

/*
Stored Procedure: [Process].[usp_ShowWorkflowSteps]

Description:
This stored procedure is designed to retrieve and display all records from the Process.[WorkFlowSteps] table. 
It is intended to provide a comprehensive view of all workflow steps that have been logged in the system, 
offering insights into the various processes and their execution details.

-- =============================================
-- Author:		Aleksandra Georgievska
-- Create date: 11/13/23
-- Description:	Show table of all workflow steps
-- =============================================
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [Process].[usp_ShowWorkflowSteps]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;
    SELECT *
    FROM [Process].[WorkFlowSteps];
END
GO

/*
Stored Procedure: Process.[usp_TrackWorkFlow]

Description:
This stored procedure is designed to track and log each step of various workflows within the system. 
It inserts records into the [WorkflowSteps] table, capturing key details about each workflow step, 
such as its description, the number of table rows affected, and the start and end times. 
This procedure is instrumental in maintaining an audit trail and enhancing transparency in automated processes.


-- =============================================
-- Author:		Aleksandra Georgievska
-- Create date: 11/13/23
-- Description:	Keep track of all workflow steps
-- =============================================
*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [Process].[usp_TrackWorkFlow]
    -- Add the parameters for the stored procedure here
    @WorkflowDescription NVARCHAR(100),
    @WorkFlowStepTableRowCount INT,
    @StartingDateTime DATETIME2,
    @EndingDateTime DATETIME2,
    @QueryTime BIGINT,
    @UserAuthorizationKey INT
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for procedure here
    INSERT INTO [Process].[WorkflowSteps]
        (
        WorkFlowStepDescription,
        WorkFlowStepTableRowCount,
        StartingDateTime,
        EndingDateTime,
        [QueryTime (ms)],
        [Class Time],
        UserAuthorizationKey
        )
    VALUES
        (@WorkflowDescription, 
        @WorkFlowStepTableRowCount, 
        @StartingDateTime, 
        @EndingDateTime, 
        @QueryTime, 
        '9:15',
        @UserAuthorizationKey);

END;
GO




/*

Stored Procedure: Process.[Load_UserAuthorization]

Description: Prepopulating the UserAuthorization Table with the Group Names 

-- =============================================
-- Author:		Aleksandra Georgievska
-- Create date: 11/126/23
-- Description:	Load the names & default values into the user authorization table
-- =============================================
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [Project3].[Load_UserAuthorization]
    @UserAuthorizationKey INT
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    DECLARE @StartingDateTime DATETIME2 = SYSDATETIME();

    INSERT INTO [DbSecurity].[UserAuthorization]
    ([GroupMemberLastName],[GroupMemberFirstName])
    VALUES

            ('Georgievska','Aleksandra'),
            ('Yakubova','Sigalita'),
            ('Kong','Nicholas'),
            ('Wray','Edwin'),
            ('Ahmed','Ahnaf'),
            ('Richman','Aryeh');

    DECLARE @WorkFlowStepTableRowCount INT;
    SET @WorkFlowStepTableRowCount = 6;
    DECLARE @EndingDateTime DATETIME2 = SYSDATETIME();
    DECLARE @QueryTime BIGINT = CAST(DATEDIFF(MILLISECOND, @StartingDateTime, @EndingDateTime) AS bigint);
    EXEC [Process].[usp_TrackWorkFlow] 'Add Users',
                                       @WorkFlowStepTableRowCount,
                                       @StartingDateTime,
                                       @EndingDateTime,
                                       @QueryTime,
                                       @UserAuthorizationKey;
END;
GO





/*
Stored Procedure: [Project3].[AddForeignKeysToClassSchedule]

Description:
This procedure is responsible for establishing foreign key relationships across various tables in 
the database. It adds constraints to link fact and dimension tables to ensure referential integrity. 
The procedure also associates dimension tables with the UserAuthorization table, thereby establishing 
a traceable link between data records and the users responsible for their creation or updates.

-- =============================================
-- Author:		Aleksandra Georgievska
-- Create date: 11/13/23
-- Description:	Add the foreign keys to the start Schema database
-- =============================================
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [Project3].[AddForeignKeysToClassSchedule]
    @UserAuthorizationKey INT
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    DECLARE @StartingDateTime DATETIME2 = SYSDATETIME();

    -- Aleks
    ALTER TABLE [Process].[WorkflowSteps]
    ADD CONSTRAINT FK_WorkFlowSteps_UserAuthorization
        FOREIGN KEY (UserAuthorizationKey)
        REFERENCES [DbSecurity].[UserAuthorization] (UserAuthorizationKey);

    -- add more here...




    DECLARE @WorkFlowStepTableRowCount INT;
    SET @WorkFlowStepTableRowCount = 0;
    DECLARE @EndingDateTime DATETIME2 = SYSDATETIME();
    DECLARE @QueryTime BIGINT = CAST(DATEDIFF(MILLISECOND, @StartingDateTime, @EndingDateTime) AS bigint);
    EXEC [Process].[usp_TrackWorkFlow] 'Add Foreign Keys',
                                       @WorkFlowStepTableRowCount,
                                       @StartingDateTime,
                                       @EndingDateTime,
                                       @QueryTime,
                                       @UserAuthorizationKey;
END;
GO



/*
Stored Procedure: [Project3].[DropForeignKeysFromClassSchedule]

Description:
This procedure is designed to remove foreign key constraints from various tables in the database. 
It primarily focuses on dropping constraints that link fact and dimension tables as well as the 
constraints linking dimension tables to the UserAuthorization table. This is typically performed 
in preparation for data loading operations that require constraint-free bulk data manipulations.

-- =============================================
-- Author:		Aleksandra Georgievska
-- Create date: 11/13/23
-- Description:	Drop the foreign keys from the start Schema database
-- =============================================

*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [Project3].[DropForeignKeysFromClassSchedule]
    @UserAuthorizationKey INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartingDateTime DATETIME2 = SYSDATETIME();

    -- Aleks
    ALTER TABLE [Process].[WorkflowSteps] DROP CONSTRAINT FK_WorkFlowSteps_UserAuthorization;

    -- add more here...

    DECLARE @WorkFlowStepTableRowCount INT;
    SET @WorkFlowStepTableRowCount = 0;
    DECLARE @EndingDateTime DATETIME2 = SYSDATETIME();
    DECLARE @QueryTime BIGINT = CAST(DATEDIFF(MILLISECOND, @StartingDateTime, @EndingDateTime) AS bigint);
    EXEC [Process].[usp_TrackWorkFlow] 'Drop Foreign Keys',
                                       @WorkFlowStepTableRowCount,
                                       @StartingDateTime,
                                       @EndingDateTime,
                                       @QueryTime,
                                       @UserAuthorizationKey;
END;
GO




/*
Stored Procedure: Project2.[TruncateClassScheduleData]

Description:
This procedure is designed to truncate tables in the schema of the data warehouse. 
It removes all records from specified dimension and fact tables and restarts the 
associated sequences. This action is essential for data refresh scenarios where 
existing data needs to be cleared before loading new data.

-- =============================================
-- Author:		Nicholas Kong
-- Create date: 11/13/2023
-- Description:	Truncate the star schema 
-- =============================================
*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [Project3].[TruncateClassScheduleData]
    @UserAuthorizationKey int

AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;
    DECLARE @StartingDateTime DATETIME2 = SYSDATETIME();
    
    -- Aleks
    ALTER SEQUENCE [PkSequence].[UserAuthorizationSequenceObject] RESTART WITH 1;
    TRUNCATE TABLE [DbSecurity].[UserAuthorization]
    ALTER SEQUENCE [PkSequence].[WorkFlowStepsSequenceObject] RESTART WITH 1;
    TRUNCATE TABLE [Process].[WorkFlowSteps]

    
    -- add more here...



    DECLARE @WorkFlowStepTableRowCount INT;
    SET @WorkFlowStepTableRowCount = 0;
    DECLARE @EndingDateTime DATETIME2 = SYSDATETIME();
    DECLARE @QueryTime BIGINT = CAST(DATEDIFF(MILLISECOND, @StartingDateTime, @EndingDateTime) AS bigint);
    EXEC [Process].[usp_TrackWorkFlow] 'Truncate Data',
                                       @WorkFlowStepTableRowCount,
                                       @StartingDateTime,
                                       @EndingDateTime,
                                       @QueryTime,
                                       @UserAuthorizationKey;
END;
GO



/*
Stored Procedure: Project2.[ShowTableStatusRowCount]

Description:
This procedure is designed to report the row count of various tables in the database, 
providing a snapshot of the current data volume across different tables. 
The procedure also logs this operation, including user authorization keys and timestamps, 
to maintain an audit trail.

-- =============================================
-- Author:		Aryeh Richman
-- Create date: 11/13/23
-- Description:	Populate a table to show the status of the row counts
-- =============================================
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [Project3].[ShowTableStatusRowCount]
    @TableStatus VARCHAR(64),
    @UserAuthorizationKey INT
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;
    DECLARE @DateAdded DATETIME2 = SYSDATETIME();

    DECLARE @DateOfLastUpdate DATETIME2 = SYSDATETIME();

    DECLARE @StartingDateTime DATETIME2 = SYSDATETIME();

    DECLARE @WorkFlowStepTableRowCount INT = 0;

    -- Aleks
    SELECT TableStatus = @TableStatus,
            TableName = '[DbSecurity].[UserAuthorization]',
            [Row Count] = COUNT(*)
        FROM [DbSecurity].[UserAuthorization]
    UNION ALL
        SELECT TableStatus = @TableStatus,
            TableName = '[Process].[WorkflowSteps]',
            [Row Count] = COUNT(*)
        FROM [Process].[WorkflowSteps];
    
    -- add more here... 



    DECLARE @EndingDateTime DATETIME2 = SYSDATETIME();
    DECLARE @QueryTime BIGINT = CAST(DATEDIFF(MILLISECOND, @StartingDateTime, @EndingDateTime) AS bigint);
    EXEC [Process].[usp_TrackWorkFlow] 'Procedure: Project3[ShowStatusRowCount] loads data into ShowTableStatusRowCount',
                                       @WorkFlowStepTableRowCount,
                                       @StartingDateTime,
                                       @EndingDateTime,
                                       @QueryTime,
                                       @UserAuthorizationKey;
END;
GO






-- add more stored procedures here... 







----------------------------------------------- CREATE VIEWS -------------------------------------------------------






--------------------------------------- DB CONTROLLER STORED PROCEDURES ----------------------------------------------

/*
-- =============================================
-- Author:		Aleksandra Georgievska
-- Create date: 11/14/23
-- Description:	Clears all data from the Class Schedule db
-- =============================================
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [Project3].[TruncateClassScheduleDatabase]
    @UserAuthorizationKey INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartingDateTime DATETIME2 = SYSDATETIME();

    -- Drop All of the foreign keys prior to truncating tables in the Class Schedule db
    EXEC [Project3].[DropForeignKeysFromClassSchedule] @UserAuthorizationKey = 1;

    --	Check row count before truncation
    EXEC [Project3].[ShowTableStatusRowCount] @UserAuthorizationKey = 6,  
		@TableStatus = N'''Pre-truncate of tables'''
    
    --	Always truncate the Star Schema Data
    EXEC  [Project3].[TruncateClassScheduleData] @UserAuthorizationKey = 3;

    --	Check row count AFTER truncation
    EXEC [Project3].[ShowTableStatusRowCount] @UserAuthorizationKey = 6,  
		@TableStatus = N'''Post-truncate of tables'''
END;
GO


/*
This T-SQL script is for creating a stored procedure named LoadClassScheduleDatabase within a SQL Server database, likely for the 
purpose of managing and updating a star schema data warehouse structure. Here's a breakdown of what this script does:



-- =============================================
-- Author:		Aleksandra Georgievska
-- Create date: 11/14/23
-- Description:	Procedure runs other stored procedures to populate the data
-- =============================================
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [Project3].[LoadClassScheduleDatabase]
    @UserAuthorizationKey INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartingDateTime DATETIME2 = SYSDATETIME();

    /*
            Note: User Authorization keys are hardcoded, each representing a different group user 
                    Aleksandra Georgievska → User Key 1
                    Sigalita Yakubova → User Key 2
                    Nicholas Kong → User Key 3
                    Edwin Wray → User Key 4
                    Ahnaf Ahmed → User Key 5
                    Aryeh Richman → User Key 6
    */

    -- ADD EXEC COMMANDS:

    -- Aleks
    EXEC [Project3].[Load_UserAuthorization] @UserAuthorizationKey = 1


    -- add more here... 



    --	Check row count before truncation
    EXEC [Project3].[ShowTableStatusRowCount] @UserAuthorizationKey = 6,  -- Change to the appropriate UserAuthorizationKey
		@TableStatus = N'''Row Count after loading the Class Schedule db'''

END;
GO



---------------------------------------- EXEC COMMANDS TO MANAGE THE DB -------------------------------------------------

-- run the following command to LOAD the database from SCRATCH 
-- EXEC [Project3].[LoadClassScheduleDatabase]  @UserAuthorizationKey = 1;

-- run the following 3 exec commands to TRUNCATE and LOAD the database 
-- EXEC [Project3].[TruncateClassScheduleDatabase] @UserAuthorizationKey = 1;
-- EXEC [Project3].[LoadClassScheduleDatabase]  @UserAuthorizationKey = 1;
--	Recreate all of the foreign keys after loading the Class Schedule schema
-- EXEC [Project3].[AddForeignKeysToClassSchedule] @UserAuthorizationKey = 1; 

-- run the following to show the workflow steps table 
-- EXEC [Process].[usp_ShowWorkflowSteps]
