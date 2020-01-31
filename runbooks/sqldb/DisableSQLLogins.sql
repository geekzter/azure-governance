DECLARE @name VARCHAR(50) -- login name 
DECLARE @sql VARCHAR(500)
DECLARE db_logins CURSOR FOR 
SELECT name FROM sys.sql_logins
WHERE name <> 'ciopadmin'
AND is_disabled=0
AND type_desc='SQL_Login';

OPEN db_logins  
FETCH NEXT FROM db_logins INTO @name  

WHILE @@FETCH_STATUS = 0  
BEGIN  
	SELECT @sql = CONCAT('alter login ', @name, ' disable')

	EXEC (@sql)

    FETCH NEXT FROM db_logins INTO @name 
END 

CLOSE db_logins  
DEALLOCATE db_logins

GO