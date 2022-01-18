import psycopg2
import psycopg2.extras
import logging

log = logging.getLogger()
log.setLevel(logging.INFO)

class ConnectionParameters:
    def __init__(self, host="localhost", port=5432, database="postgres", username="admin", password="secret"):
        self.__host = host
        self.__port = port
        self.__database = database
        self.__username = username
        self.__password = password
        
    def host(self):
        return self.__host
        
    def port(self):
        return self.__port
        
    def database(self):
        return self.__database
        
    def username(self):
        return self.__username
        
    def password(self):
        return self.__password

class Database:
    def __init__(self, connection_parameters=None):
        self.__connection_parameters = connection_parameters
        self.__database_connection = ""
        pass
    
    def config(self, connection_parameters):
        self.__connection_parameters = connection_parameters
        
    def connection_string(self, connection_parameters):
        cp = connection_parameters if connection_parameters is not None else self.__connection_parameters if self.__connection_parameters is not None else None
        if cp is None:
            raise ValueError("Database() missing ConnectionParameters")
        self.__database_connection = f"{cp.database()} on {cp.host()}"
        return "dbname='" + cp.database() + "' user='" + cp.username() + "' password='" + cp.password() + "'host='" + cp.host() + "'"
        
    def connect(self, connection_parameters=None):
        try:
            self.__connection = psycopg2.connect(self.connection_string(connection_parameters))
            log.info(f"Database() connected to: {self.__database_connection}")
        except psycopg2.errors.OperationalError as e:
            log.error(f"Database() connection error: {e} - {e.diag.severity} - {e.diag.message_primary}")
            raise e

    def disconnect(self):
        self.__connection.close()
        self.__database_connection = ""
    
    def select(self, query):
        cursor = self.__connection.cursor()
        cursor.execute(query)
        rows = cursor.fetchall()
        cursor.close()
        return rows
    
    def insert(self, query):
        pass
    
    def update(self, query):
        cursor = self.__connection.cursor()
        cursor.execute(query)
        count = cursor.rowcount
        self.commit()
        cursor.close()
        return count
    
    def delete(self, query):
        pass
        
    def commit(self):
        self.__connection.commit()
        
    def rollback(self):
        pass
    