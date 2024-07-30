--1
--1.1

SELECT
    e1.ID AS EmployeeID,
    e1.NAME AS EmployeeName,
    e1.SALARY AS EmployeeSalary,
    e2.ID AS ChieffID,
    e2.NAME AS ChieffName,
    e2.SALARY AS ChieffSalary
FROM
    EMPLOYEE e1
INNER JOIN
    EMPLOYEE e2 ON e1.CHIEFF_ID = e2.ID
WHERE
    e1.SALARY > e2.SALARY;

--1.2

SELECT
    e1.ID AS EmployeeID,
    e1.NAME AS EmployeeName,
    e1.DEPARTMENT_ID AS DepartmentID,
    e1.SALARY AS EmployeeSalary
FROM
    EMPLOYEE e1
WHERE
    e1.SALARY = (SELECT MAX(e2.SALARY)
                 FROM EMPLOYEE e2
                 WHERE e2.DEPARTMENT_ID = e1.DEPARTMENT_ID);

--1.3

SELECT
    DEPARTMENT_ID,
    COUNT(*) AS EmployeeCount
FROM
    EMPLOYEE
GROUP BY
    DEPARTMENT_ID
HAVING
    COUNT(*) <= 3;


--1.4

SELECT
    e1.ID AS EmployeeID,
    e1.NAME AS EmployeeName,
    e1.DEPARTMENT_ID AS DepartmentID,
    e1.CHIEFF_ID AS ChieffID
FROM
    EMPLOYEE e1
LEFT JOIN
    EMPLOYEE e2 ON e1.CHIEFF_ID = e2.ID AND e1.DEPARTMENT_ID = e2.DEPARTMENT_ID
WHERE
    e1.CHIEFF_ID IS NULL OR e2.ID IS NULL;

--1.5

WITH DepartmentSalaries AS (
    SELECT
        DEPARTMENT_ID,
        SUM(SALARY) AS TotalSalary
    FROM
        EMPLOYEE
    GROUP BY
        DEPARTMENT_ID
),
MaxDepartmentSalaries AS (
    SELECT
        DEPARTMENT_ID,
        TotalSalary,
        RANK() OVER (ORDER BY TotalSalary DESC) AS SalaryRank
    FROM
        DepartmentSalaries
)
SELECT
    DEPARTMENT_ID,
    TotalSalary
FROM
    MaxDepartmentSalaries
WHERE
    SalaryRank = 1;


--2

CREATE FUNCTION [dbo].[fFindMiddleSubstring]
(
    @Source varchar(max), -- исходный текст
    @LeftSubstring varchar(500), -- левая подстрока
    @RightSubstring varchar(500), -- правая подстрока
    @StartPos int, -- начальная позиция для поиска
    @TrimEx int -- битовая маска комбинации действий с найденной подстрокой
)
RETURNS 
@RsltTable TABLE 
(
    ResString varchar(max), -- результат
    EndPos int -- конечная позиция найденного фрагмента в исходном тексте
)
AS
BEGIN
    DECLARE @LeftPos int, @RightPos int, @SubString varchar(max)
    
    -- Найти позицию левой подстроки
    SET @LeftPos = CHARINDEX(@LeftSubstring, @Source, @StartPos)
    IF @LeftPos = 0
        RETURN

    -- Найти позицию правой подстроки после левой подстроки
    SET @RightPos = CHARINDEX(@RightSubstring, @Source, @LeftPos + LEN(@LeftSubstring))
    IF @RightPos = 0
        RETURN

    -- Извлечь подстроку между найденными позициями
    SET @SubString = SUBSTRING(@Source, @LeftPos + LEN(@LeftSubstring), @RightPos - @LeftPos - LEN(@LeftSubstring))

    -- Применить битовую маску для обработки подстроки
    IF @TrimEx & 1 = 1
        SET @SubString = LTRIM(RTRIM(@SubString))
    IF @TrimEx & 2 = 2
        SET @SubString = REPLACE(@SubString, CHAR(160), '')
    IF @TrimEx & 4 = 4
        SET @SubString = REPLACE(@SubString, CHAR(160), ' ')
    IF @TrimEx & 8 = 8
        SET @SubString = REPLACE(@SubString, '&quot;', '"')
    IF @TrimEx & 16 = 16
    BEGIN
        SET @SubString = REPLACE(@SubString, '.', '')
        SET @SubString = REPLACE(@SubString, ',', '.')
    END
    IF @TrimEx & 32 = 32
        SET @SubString = REPLACE(@SubString, ' ', '')
    IF @TrimEx & 64 = 64
    BEGIN
        SET @SubString = REPLACE(@SubString, CHAR(13), '')
        SET @SubString = REPLACE(@SubString, CHAR(10), '')
    END

    -- Вставить результат в табличную переменную
    INSERT INTO @RsltTable (ResString, EndPos)
    VALUES (@SubString, @RightPos + LEN(@RightSubstring))

    RETURN
END
GO

--3

CREATE PROCEDURE [dbo].[pFindMiddleSubstring]
    @Source varchar(max),   -- исходный текст
    @LeftSubstring varchar(500),   -- левая подстрока
    @RightSubstring varchar(500),   -- правая подстрока
    @StartPos int,   -- начальная позиция для поиска
    @TrimEx int,   -- битовая маска комбинации действий с найденной подстрокой
    @Result varchar(max) OUTPUT,   -- результат
    @EndPos int OUTPUT   -- конечная позиция
AS
BEGIN
    DECLARE @LeftPos int, @RightPos int, @SubString varchar(max)

    -- Найти позицию левой подстроки
    SET @LeftPos = CHARINDEX(@LeftSubstring, @Source, @StartPos)
    IF @LeftPos = 0
    BEGIN
        SET @Result = NULL
        SET @EndPos = 0
        RETURN
    END

    -- Найти позицию правой подстроки после левой подстроки
    SET @RightPos = CHARINDEX(@RightSubstring, @Source, @LeftPos + LEN(@LeftSubstring))
    IF @RightPos = 0
    BEGIN
        SET @Result = NULL
        SET @EndPos = 0
        RETURN
    END

    -- Извлечь подстроку между найденными позициями
    SET @SubString = SUBSTRING(@Source, @LeftPos + LEN(@LeftSubstring), @RightPos - @LeftPos - LEN(@LeftSubstring))

    -- Применить битовую маску для обработки подстроки
    IF @TrimEx & 1 = 1
        SET @SubString = LTRIM(RTRIM(@SubString))
    IF @TrimEx & 2 = 2
        SET @SubString = REPLACE(@SubString, CHAR(160), '')
    IF @TrimEx & 4 = 4
        SET @SubString = REPLACE(@SubString, CHAR(160), ' ')
    IF @TrimEx & 8 = 8
        SET @SubString = REPLACE(@SubString, '&quot;', '"')
    IF @TrimEx & 16 = 16
    BEGIN
        SET @SubString = REPLACE(@SubString, '.', '')
        SET @SubString = REPLACE(@SubString, ',', '.')
    END
    IF @TrimEx & 32 = 32
        SET @SubString = REPLACE(@SubString, ' ', '')
    IF @TrimEx & 64 = 64
    BEGIN
        SET @SubString = REPLACE(@SubString, CHAR(13), '')
        SET @SubString = REPLACE(@SubString, CHAR(10), '')
    END

    -- Установить результат и конечную позицию
    SET @Result = @SubString
    SET @EndPos = @RightPos + LEN(@RightSubstring)
END
GO
