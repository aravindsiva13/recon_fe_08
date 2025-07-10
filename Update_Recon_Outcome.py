# import mysql.connector
# from mysql.connector import Error

# # Function to execute the SQL commands
# def execute_sql_commands():
#     try:
#         # Connect to the MySQL database
#         connection = mysql.connector.connect(
#             host='localhost',  # Replace with your host
#             database='reconciliation',  # Replace with your database name
#             user='root',  # Replace with your username
#             password='Templerun@2'  # Replace with your password
#         )

#         if connection.is_connected():
#             cursor = connection.cursor()
            
#             # Start by clearing the Recon_Outcome table
#             delete_query = "DELETE FROM Recon_Outcome;"
#             cursor.execute(delete_query)
#             print("Deleted records from Recon_Outcome.")

#             # Insert new records into Recon_Outcome
#             insert_query = """
#             INSERT INTO Recon_Outcome 
#             (
#             (SELECT DISTINCT Txn_RefNo, Txn_Machine, Txn_MID, 0, 0, 0, 0, 0 
#             FROM payment_refund pr 
#             WHERE (left(pr.Txn_Source,6) = 'iCLOUD') 
#             AND ((left(pr.Txn_Type,3) = 'UPI') OR (pr.Txn_Type = ' (manual)')))
#             UNION 
#             (SELECT DISTINCT Txn_RefNo, Txn_Machine, Txn_MID, 0, 0, 0, 0, 0 
#             FROM paytm_phonepe pp)
#             );
#             """
#             cursor.execute(insert_query)
#             print("Inserted new records into Recon_Outcome.")

#             # Update the Recon_Outcome table
#             update_queries = [
#                 """UPDATE Recon_Outcome RO 
#                    SET PTPP_Payment = (SELECT COALESCE(SUM(pp.Txn_Amount), 0) 
#                    FROM reconciliation.paytm_phonepe pp 
#                    WHERE pp.Txn_Type = 'PAYMENT' AND pp.Txn_RefNo = ro.Txn_RefNo);""",
#                 """UPDATE Recon_Outcome RO 
#                    SET PTPP_Refund = (SELECT COALESCE(SUM(pp.Txn_Amount), 0) 
#                    FROM reconciliation.paytm_phonepe pp 
#                    WHERE pp.Txn_Type = 'REFUND' AND pp.Txn_RefNo = ro.Txn_RefNo);""",
#                 """UPDATE Recon_Outcome RO 
#                    SET Cloud_Payment = (SELECT COALESCE(SUM(pr.Txn_Amount), 0) 
#                    FROM reconciliation.payment_refund pr 
#                    WHERE pr.Txn_RefNo = ro.Txn_RefNo 
#                    AND pr.Txn_Source = 'iCLOUD-PAYMENT' 
#                    AND (pr.Txn_Type = 'UPI / Wallet (Paytm)' 
#                    OR pr.Txn_Type = 'UPI / Wallet / Card (PhonePe)'));""",
#                 """UPDATE Recon_Outcome RO 
#                    SET Cloud_Refund = (SELECT COALESCE(SUM(pr.Txn_Amount), 0) 
#                    FROM reconciliation.payment_refund pr 
#                    WHERE pr.Txn_Source = 'iCLOUD-REFUND' 
#                    AND pr.Txn_Type != ' (manual)' 
#                    AND pr.Txn_RefNo = ro.Txn_RefNo);""",
#                 """UPDATE Recon_Outcome RO 
#                    SET Cloud_MRefund = (SELECT COALESCE(SUM(pr.Txn_Amount), 0) 
#                    FROM reconciliation.payment_refund pr 
#                    WHERE pr.Txn_RefNo = ro.Txn_RefNo 
#                    AND pr.Txn_Source = 'iCLOUD-REFUND' 
#                    AND pr.Txn_Type = ' (manual)');""",
#             ]

#             # Execute the update queries
#             for query in update_queries:
#                 cursor.execute(query)
#                 print(f"Executed update query: {query[:50]}...")  # Print the first 50 characters of each query for confirmation

#             # Commit the changes to the database
#             connection.commit()
#             print("All SQL commands executed successfully.")

#     except Error as e:
#         print(f"Error: {e}")
#     finally:
#         # Close the database connection
#         if connection.is_connected():
#             cursor.close()
#             connection.close()
#             print("MySQL connection is closed.")

# # Call the function to execute the SQL commands
# execute_sql_commands()


#2

# import mysql.connector
# from mysql.connector import Error
# import os
# from dotenv import load_dotenv

# # Load environment variables from .env file
# load_dotenv()

# def get_db_config():
#     """Get database configuration from .env file with fallback"""
#     return {
#         'host': os.getenv('DB_HOST', 'localhost'),
#         'user': os.getenv('DB_USER', 'root'),
#         'password': os.getenv('DB_PASSWORD', 'Templerun@2'),
#         'database': os.getenv('DB_DATABASE', 'reconciliation'),
#         'port': int(os.getenv('DB_PORT', 3306))
#     }

# # Function to execute the SQL commands
# def execute_sql_commands():
#     try:
#         # Connect to the MySQL database using config
#         connection = mysql.connector.connect(**get_db_config())

#         if connection.is_connected():
#             cursor = connection.cursor()
            
#             # Start by clearing the Recon_Outcome table
#             delete_query = "DELETE FROM recon_outcome;"
#             cursor.execute(delete_query)
#             print("Deleted records from recon_outcome.")

#             # FIXED: Insert new records into Recon_Outcome with corrected syntax
#             insert_query = """
#             INSERT INTO recon_outcome (Txn_RefNo, Txn_Machine, Txn_MID, PTPP_Payment, PTPP_Refund, Cloud_Payment, Cloud_Refund, Cloud_MRefund)
#             SELECT DISTINCT Txn_RefNo, Txn_Machine, Txn_MID, 0, 0, 0, 0, 0 
#             FROM payment_refund pr 
#             WHERE (left(pr.Txn_Source,6) = 'iCLOUD') 
#             AND ((left(pr.Txn_Type,3) = 'UPI') OR (pr.Txn_Type = ' (manual)'))
#             UNION 
#             SELECT DISTINCT Txn_RefNo, Txn_Machine, Txn_MID, 0, 0, 0, 0, 0 
#             FROM paytm_phonepe pp
#             """
#             cursor.execute(insert_query)
#             rows_inserted = cursor.rowcount
#             print(f"Inserted {rows_inserted} new records into recon_outcome.")

#             # Update the Recon_Outcome table with proper aliases
#             update_queries = [
#                 """UPDATE recon_outcome ro 
#                    SET PTPP_Payment = (SELECT COALESCE(SUM(pp.Txn_Amount), 0) 
#                    FROM reconciliation.paytm_phonepe pp 
#                    WHERE pp.Txn_Type = 'PAYMENT' AND pp.Txn_RefNo = ro.Txn_RefNo)""",
#                 """UPDATE recon_outcome ro 
#                    SET PTPP_Refund = (SELECT COALESCE(SUM(pp.Txn_Amount), 0) 
#                    FROM reconciliation.paytm_phonepe pp 
#                    WHERE pp.Txn_Type = 'REFUND' AND pp.Txn_RefNo = ro.Txn_RefNo)""",
#                 """UPDATE recon_outcome ro 
#                    SET Cloud_Payment = (SELECT COALESCE(SUM(pr.Txn_Amount), 0) 
#                    FROM reconciliation.payment_refund pr 
#                    WHERE pr.Txn_RefNo = ro.Txn_RefNo 
#                    AND pr.Txn_Source = 'iCLOUD-PAYMENT' 
#                    AND (pr.Txn_Type = 'UPI / Wallet (Paytm)' 
#                    OR pr.Txn_Type = 'UPI / Wallet / Card (PhonePe)'))""",
#                 """UPDATE recon_outcome ro 
#                    SET Cloud_Refund = (SELECT COALESCE(SUM(pr.Txn_Amount), 0) 
#                    FROM reconciliation.payment_refund pr 
#                    WHERE pr.Txn_Source = 'iCLOUD-REFUND' 
#                    AND pr.Txn_Type != ' (manual)' 
#                    AND pr.Txn_RefNo = ro.Txn_RefNo)""",
#                 """UPDATE recon_outcome ro 
#                    SET Cloud_MRefund = (SELECT COALESCE(SUM(pr.Txn_Amount), 0) 
#                    FROM reconciliation.payment_refund pr 
#                    WHERE pr.Txn_RefNo = ro.Txn_RefNo 
#                    AND pr.Txn_Source = 'iCLOUD-REFUND' 
#                    AND pr.Txn_Type = ' (manual)')"""
#             ]

#             # Execute the update queries
#             for i, query in enumerate(update_queries, 1):
#                 cursor.execute(query)
#                 rows_affected = cursor.rowcount
#                 print(f"Executed update query {i}: {rows_affected} rows affected")

#             # Commit the changes to the database
#             connection.commit()
            
#             # Verify the results
#             cursor.execute("SELECT COUNT(*) FROM recon_outcome")
#             total_count = cursor.fetchone()[0]
#             print(f" All SQL commands executed successfully.")
#             print(f" Total records in Recon_Outcome: {total_count}")
            
#             # Show sample data
#             cursor.execute("SELECT * FROM recon_outcome LIMIT 5")
#             sample_data = cursor.fetchall()
#             print(" Sample data from Recon_Outcome:")
#             for row in sample_data:
#                 print(f"   {row}")

#     except Error as e:
#         print(f" Error: {e}")
#         if connection:
#             connection.rollback()
#     finally:
#         # Close the database connection
#         if connection and connection.is_connected():
#             cursor.close()
#             connection.close()
#             print("MySQL connection is closed.")

# # Call the function to execute the SQL commands
# if __name__ == "__main__":
#     execute_sql_commands()

#3

# import mysql.connector
# from mysql.connector import Error
# import os
# from dotenv import load_dotenv

# load_dotenv()

# def get_db_config():
#     return {
#         'host': os.getenv('DB_HOST', 'localhost'),
#         'user': os.getenv('DB_USER', 'root'),
#         'password': os.getenv('DB_PASSWORD', 'Templerun@2'),
#         'database': os.getenv('DB_DATABASE', 'reconciliation'),
#         'port': int(os.getenv('DB_PORT', 3306))
#     }

# def execute_sql_commands():
#     connection = None
#     try:
#         connection = mysql.connector.connect(**get_db_config())
#         cursor = connection.cursor()
        
#         print("Starting reconciliation process...")
        
#         # Check source data availability
#         cursor.execute("SELECT COUNT(*) FROM payment_refund")
#         pr_count = cursor.fetchone()[0]
        
#         cursor.execute("SELECT COUNT(*) FROM paytm_phonepe")
#         pp_count = cursor.fetchone()[0]
        
#         print(f"Source data: payment_refund={pr_count}, paytm_phonepe={pp_count}")
        
#         if pr_count == 0 and pp_count == 0:
#             print("ERROR: Both source tables are empty!")
#             return
        
#         # Clear recon_outcome table
#         print("Clearing recon_outcome table...")
#         cursor.execute("DELETE FROM recon_outcome")
#         print(f"Cleared {cursor.rowcount} existing records")
        
#         # Build the INSERT query with better criteria detection
#         print("Analyzing source data patterns...")
        
#         # Check actual data patterns to build proper criteria
#         cursor.execute("SELECT DISTINCT Txn_Source FROM payment_refund LIMIT 10")
#         pr_sources = [row[0] for row in cursor.fetchall()]
#         print(f"payment_refund sources: {pr_sources}")
        
#         cursor.execute("SELECT DISTINCT Txn_Type FROM payment_refund LIMIT 10")
#         pr_types = [row[0] for row in cursor.fetchall()]
#         print(f"payment_refund types: {pr_types}")
        
#         # Use more flexible criteria based on actual data
#         print("Inserting records into recon_outcome...")
        
#         # More flexible INSERT - adapt to actual data patterns
#         insert_query = """
#         INSERT INTO recon_outcome (Txn_RefNo, Txn_Machine, Txn_MID, PTPP_Payment, PTPP_Refund, Cloud_Payment, Cloud_Refund, Cloud_MRefund)
#         SELECT DISTINCT 
#             COALESCE(pr.Txn_RefNo, pp.Txn_RefNo) as Txn_RefNo,
#             COALESCE(pr.Txn_Machine, pp.Txn_Machine) as Txn_Machine,
#             COALESCE(pr.Txn_MID, pp.Txn_MID) as Txn_MID,
#             0, 0, 0, 0, 0
#         FROM (
#             SELECT DISTINCT Txn_RefNo, Txn_Machine, Txn_MID FROM payment_refund 
#             WHERE Txn_RefNo IS NOT NULL AND Txn_RefNo != ''
#             UNION
#             SELECT DISTINCT Txn_RefNo, Txn_Machine, Txn_MID FROM paytm_phonepe 
#             WHERE Txn_RefNo IS NOT NULL AND Txn_RefNo != ''
#         ) AS combined_refs
#         LEFT JOIN payment_refund pr ON combined_refs.Txn_RefNo = pr.Txn_RefNo
#         LEFT JOIN paytm_phonepe pp ON combined_refs.Txn_RefNo = pp.Txn_RefNo
#         """
        
#         cursor.execute(insert_query)
#         rows_inserted = cursor.rowcount
#         print(f"Inserted {rows_inserted} records into recon_outcome")
        
#         if rows_inserted == 0:
#             print("WARNING: No records inserted. Trying alternative approach...")
            
#             # Alternative: Insert all unique references from both tables
#             alt_query = """
#             INSERT INTO recon_outcome (Txn_RefNo, Txn_Machine, Txn_MID, PTPP_Payment, PTPP_Refund, Cloud_Payment, Cloud_Refund, Cloud_MRefund)
#             SELECT DISTINCT Txn_RefNo, Txn_Machine, Txn_MID, 0, 0, 0, 0, 0 
#             FROM payment_refund 
#             WHERE Txn_RefNo IS NOT NULL AND Txn_RefNo != ''
#             UNION 
#             SELECT DISTINCT Txn_RefNo, Txn_Machine, Txn_MID, 0, 0, 0, 0, 0 
#             FROM paytm_phonepe 
#             WHERE Txn_RefNo IS NOT NULL AND Txn_RefNo != ''
#             """
#             cursor.execute(alt_query)
#             rows_inserted = cursor.rowcount
#             print(f"Alternative insert: {rows_inserted} records")
        
#         if rows_inserted == 0:
#             print("CRITICAL: Still no records inserted. Check your data!")
#             return
        
#         # Update PTPP values
#         print("Updating PTPP values...")
        
#         update_queries = [
#             # PTPP Payment
#             """UPDATE recon_outcome ro 
#                SET PTPP_Payment = (
#                    SELECT COALESCE(SUM(pp.Txn_Amount), 0) 
#                    FROM paytm_phonepe pp 
#                    WHERE pp.Txn_Type LIKE '%PAYMENT%' 
#                    AND pp.Txn_RefNo = ro.Txn_RefNo
#                )""",
            
#             # PTPP Refund  
#             """UPDATE recon_outcome ro 
#                SET PTPP_Refund = (
#                    SELECT COALESCE(SUM(pp.Txn_Amount), 0) 
#                    FROM paytm_phonepe pp 
#                    WHERE pp.Txn_Type LIKE '%REFUND%' 
#                    AND pp.Txn_RefNo = ro.Txn_RefNo
#                )""",
            
#             # Cloud Payment - more flexible matching
#             """UPDATE recon_outcome ro 
#                SET Cloud_Payment = (
#                    SELECT COALESCE(SUM(pr.Txn_Amount), 0) 
#                    FROM payment_refund pr 
#                    WHERE pr.Txn_RefNo = ro.Txn_RefNo 
#                    AND pr.Txn_Source LIKE '%PAYMENT%'
#                    AND pr.Txn_Amount > 0
#                )""",
            
#             # Cloud Refund - more flexible matching
#             """UPDATE recon_outcome ro 
#                SET Cloud_Refund = (
#                    SELECT COALESCE(SUM(ABS(pr.Txn_Amount)), 0) 
#                    FROM payment_refund pr 
#                    WHERE pr.Txn_RefNo = ro.Txn_RefNo 
#                    AND pr.Txn_Source LIKE '%REFUND%'
#                    AND pr.Txn_Type NOT LIKE '%manual%'
#                )""",
            
#             # Cloud Manual Refund
#             """UPDATE recon_outcome ro 
#                SET Cloud_MRefund = (
#                    SELECT COALESCE(SUM(ABS(pr.Txn_Amount)), 0) 
#                    FROM payment_refund pr 
#                    WHERE pr.Txn_RefNo = ro.Txn_RefNo 
#                    AND (pr.Txn_Type LIKE '%manual%' OR pr.Txn_Source LIKE '%MANUAL%')
#                )"""
#         ]
        
#         for i, query in enumerate(update_queries, 1):
#             cursor.execute(query)
#             affected = cursor.rowcount
#             print(f"Update query {i}: {affected} rows affected")
        
#         connection.commit()
        
#         # Final verification
#         cursor.execute("SELECT COUNT(*) FROM recon_outcome")
#         final_count = cursor.fetchone()[0]
        
#         cursor.execute("""
#             SELECT 
#                 COUNT(*) as total,
#                 SUM(CASE WHEN PTPP_Payment > 0 THEN 1 ELSE 0 END) as ptpp_pay,
#                 SUM(CASE WHEN PTPP_Refund > 0 THEN 1 ELSE 0 END) as ptpp_ref,
#                 SUM(CASE WHEN Cloud_Payment > 0 THEN 1 ELSE 0 END) as cloud_pay,
#                 SUM(CASE WHEN Cloud_Refund > 0 THEN 1 ELSE 0 END) as cloud_ref,
#                 SUM(CASE WHEN Cloud_MRefund > 0 THEN 1 ELSE 0 END) as cloud_manual
#             FROM recon_outcome
#         """)
#         stats = cursor.fetchone()
        
#         print(f"\n=== FINAL RESULTS ===")
#         print(f"Total recon_outcome records: {final_count}")
#         print(f"Records with PTPP_Payment > 0: {stats[1]}")
#         print(f"Records with PTPP_Refund > 0: {stats[2]}")
#         print(f"Records with Cloud_Payment > 0: {stats[3]}")
#         print(f"Records with Cloud_Refund > 0: {stats[4]}")
#         print(f"Records with Cloud_MRefund > 0: {stats[5]}")
        
#         # Show sample results
#         cursor.execute("SELECT * FROM recon_outcome WHERE (PTPP_Payment + PTPP_Refund + Cloud_Payment + Cloud_Refund + Cloud_MRefund) > 0 LIMIT 3")
#         samples = cursor.fetchall()
#         print(f"\nSample populated records:")
#         for row in samples:
#             print(f"  {row}")
        
#         print("\n✅ Reconciliation process completed successfully!")
        
#     except Error as e:
#         print(f"Database Error: {e}")
#         if connection:
#             connection.rollback()
#     except Exception as e:
#         print(f"Error: {e}")
#         if connection:
#             connection.rollback()
#     finally:
#         if connection and connection.is_connected():
#             cursor.close()
#             connection.close()
#             print("Database connection closed.")

# if __name__ == "__main__":
#     execute_sql_commands()


#4


# # SIMPLE FIX: Replace your entire update_recon_outcome.py with this:

# import mysql.connector
# from mysql.connector import Error
# import os
# from dotenv import load_dotenv

# load_dotenv()

# def get_db_config():
#     return {
#         'host': os.getenv('DB_HOST', 'localhost'),
#         'user': os.getenv('DB_USER', 'root'),
#         'password': os.getenv('DB_PASSWORD', 'Templerun@2'),
#         'database': os.getenv('DB_DATABASE', 'reconciliation'),
#         'port': int(os.getenv('DB_PORT', 3306))
#     }

# def simple_fix():
#     connection = None
#     try:
#         connection = mysql.connector.connect(**get_db_config())
#         cursor = connection.cursor()
        
#         print(" Starting SIMPLE reconciliation fix...")
        
#         # Step 1: Clear recon_outcome table
#         print(" Clearing recon_outcome table...")
#         cursor.execute("DELETE FROM recon_outcome")
#         print(f"   Cleared {cursor.rowcount} old records")
        
#         # Step 2: Insert ALL unique transaction references
#         print(" Inserting all unique transaction references...")
        
#         insert_sql = """
#         INSERT INTO recon_outcome (Txn_RefNo, Txn_Machine, Txn_MID, PTPP_Payment, PTPP_Refund, Cloud_Payment, Cloud_Refund, Cloud_MRefund)
#         SELECT DISTINCT 
#             COALESCE(pp.Txn_RefNo, pr.Txn_RefNo) as Txn_RefNo,
#             COALESCE(pp.Txn_Machine, pr.Txn_Machine) as Txn_Machine,
#             COALESCE(pp.Txn_MID, pr.Txn_MID) as Txn_MID,
#             0, 0, 0, 0, 0
#         FROM (
#             SELECT DISTINCT Txn_RefNo FROM paytm_phonepe WHERE Txn_RefNo IS NOT NULL AND Txn_RefNo != ''
#             UNION
#             SELECT DISTINCT Txn_RefNo FROM payment_refund WHERE Txn_RefNo IS NOT NULL AND Txn_RefNo != ''
#         ) refs
#         LEFT JOIN paytm_phonepe pp ON refs.Txn_RefNo = pp.Txn_RefNo
#         LEFT JOIN payment_refund pr ON refs.Txn_RefNo = pr.Txn_RefNo
#         """
        
#         cursor.execute(insert_sql)
#         inserted = cursor.rowcount
#         print(f"    Inserted {inserted} transaction references")
        
#         if inserted == 0:
#             print("    ERROR: No data inserted! Check your source tables!")
#             return
        
#         # Step 3: Update ALL amounts in ONE query (SIMPLE approach)
#         print("3️⃣ Updating all amounts...")
        
#         # Single query that updates everything at once
#         update_sql = """
#         UPDATE recon_outcome ro
#         SET 
#             PTPP_Payment = COALESCE((
#                 SELECT SUM(Txn_Amount) 
#                 FROM paytm_phonepe pp 
#                 WHERE pp.Txn_RefNo = ro.Txn_RefNo AND Txn_Amount > 0
#             ), 0),
            
#             PTPP_Refund = COALESCE((
#                 SELECT SUM(ABS(Txn_Amount)) 
#                 FROM paytm_phonepe pp 
#                 WHERE pp.Txn_RefNo = ro.Txn_RefNo AND Txn_Amount < 0
#             ), 0),
            
#             Cloud_Payment = COALESCE((
#                 SELECT SUM(Txn_Amount) 
#                 FROM payment_refund pr 
#                 WHERE pr.Txn_RefNo = ro.Txn_RefNo AND Txn_Amount > 0
#             ), 0),
            
#             Cloud_Refund = COALESCE((
#                 SELECT SUM(ABS(Txn_Amount)) 
#                 FROM payment_refund pr 
#                 WHERE pr.Txn_RefNo = ro.Txn_RefNo AND Txn_Amount < 0
#             ), 0)
#         """
        
#         cursor.execute(update_sql)
#         updated = cursor.rowcount
#         print(f"    Updated {updated} records with amounts")
        
#         connection.commit()
        
#         # Step 4: Show results
#         print("4️ Final results:")
#         cursor.execute("""
#             SELECT 
#                 COUNT(*) as total,
#                 SUM(CASE WHEN PTPP_Payment > 0 THEN 1 ELSE 0 END) as ptpp_payments,
#                 SUM(CASE WHEN PTPP_Refund > 0 THEN 1 ELSE 0 END) as ptpp_refunds,
#                 SUM(CASE WHEN Cloud_Payment > 0 THEN 1 ELSE 0 END) as cloud_payments,
#                 SUM(CASE WHEN Cloud_Refund > 0 THEN 1 ELSE 0 END) as cloud_refunds
#             FROM recon_outcome
#         """)
        
#         stats = cursor.fetchone()
#         print(f"    Total records: {stats[0]}")
#         print(f"    PTPP Payments: {stats[1]}")
#         print(f"    PTPP Refunds: {stats[2]}")
#         print(f"    Cloud Payments: {stats[3]}")
#         print(f"    Cloud Refunds: {stats[4]}")
        
#         if stats[1] > 0 or stats[2] > 0 or stats[3] > 0 or stats[4] > 0:
#             print("   SUCCESS! Data has been populated!")
#         else:
#             print("    WARNING: All amounts are still zero. Check your source data!")
        
#         print(" Simple fix completed!")
        
#     except Error as e:
#         print(f" Database Error: {e}")
#         if connection:
#             connection.rollback()
#     except Exception as e:
#         print(f" Error: {e}")
#         if connection:
#             connection.rollback()
#     finally:
#         if connection and connection.is_connected():
#             cursor.close()
#             connection.close()

# if __name__ == "__main__":
#     simple_fix()


#5


# import mysql.connector
# from mysql.connector import Error
# import os
# from dotenv import load_dotenv

# load_dotenv()

# def get_db_config():
#     return {
#         'host': os.getenv('DB_HOST', 'localhost'),
#         'user': os.getenv('DB_USER', 'root'),
#         'password': os.getenv('DB_PASSWORD', 'Templerun@2'),
#         'database': os.getenv('DB_DATABASE', 'reconciliation'),
#         'port': int(os.getenv('DB_PORT', 3306))
#     }

# def execute_sql_commands():
#     connection = None
#     try:
#         # Connect to the MySQL database
#         connection = mysql.connector.connect(**get_db_config())
        
#         if connection.is_connected():
#             cursor = connection.cursor()
            
#             print("🔄 Starting reconciliation process (Original Logic)...")
            
#             # Check source data first
#             cursor.execute("SELECT COUNT(*) FROM payment_refund")
#             pr_count = cursor.fetchone()[0]
            
#             cursor.execute("SELECT COUNT(*) FROM paytm_phonepe")
#             pp_count = cursor.fetchone()[0]
            
#             print(f" Source data: payment_refund={pr_count}, paytm_phonepe={pp_count}")
            
#             if pr_count == 0 and pp_count == 0:
#                 print(" ERROR: Both source tables are empty!")
#                 return
            
#             # Step 1: Clear the Recon_Outcome table
#             print("1️ Clearing Recon_Outcome table...")
#             delete_query = "DELETE FROM Recon_Outcome"
#             cursor.execute(delete_query)
#             print(f"   Deleted {cursor.rowcount} existing records from Recon_Outcome.")

#             # Step 2: Insert new records into Recon_Outcome (FIXED VERSION of your original)
#             print("2️ Inserting records into Recon_Outcome...")
            
#             # CORRECTED: Your original INSERT with proper syntax
#             insert_query = """
#             INSERT INTO Recon_Outcome (Txn_RefNo, Txn_Machine, Txn_MID, PTPP_Payment, PTPP_Refund, Cloud_Payment, Cloud_Refund, Cloud_MRefund)
#             (SELECT DISTINCT Txn_RefNo, Txn_Machine, Txn_MID, 0, 0, 0, 0, 0 
#              FROM payment_refund pr 
#              WHERE (LEFT(pr.Txn_Source, 6) = 'iCLOUD') 
#              AND ((LEFT(pr.Txn_Type, 3) = 'UPI') OR (pr.Txn_Type = ' (manual)')))
#             UNION 
#             (SELECT DISTINCT Txn_RefNo, Txn_Machine, Txn_MID, 0, 0, 0, 0, 0 
#              FROM paytm_phonepe pp)
#             """
            
#             cursor.execute(insert_query)
#             rows_inserted = cursor.rowcount
#             print(f"    Inserted {rows_inserted} new records into Recon_Outcome.")
            
#             if rows_inserted == 0:
#                 print("  WARNING: No records inserted. Checking data patterns...")
                
#                 # Debug: Check actual data patterns
#                 cursor.execute("SELECT DISTINCT LEFT(Txn_Source, 10), LEFT(Txn_Type, 20) FROM payment_refund LIMIT 5")
#                 pr_patterns = cursor.fetchall()
#                 print(f"   payment_refund patterns: {pr_patterns}")
                
#                 cursor.execute("SELECT COUNT(*) FROM paytm_phonepe WHERE Txn_RefNo IS NOT NULL")
#                 pp_refs = cursor.fetchone()[0]
#                 print(f"   paytm_phonepe non-null Txn_RefNo: {pp_refs}")
                
#                 # Fallback: Insert all records if specific criteria don't match
#                 print("   Trying fallback insertion...")
#                 fallback_query = """
#                 INSERT INTO Recon_Outcome (Txn_RefNo, Txn_Machine, Txn_MID, PTPP_Payment, PTPP_Refund, Cloud_Payment, Cloud_Refund, Cloud_MRefund)
#                 SELECT DISTINCT Txn_RefNo, Txn_Machine, Txn_MID, 0, 0, 0, 0, 0 
#                 FROM payment_refund 
#                 WHERE Txn_RefNo IS NOT NULL AND Txn_RefNo != ''
#                 UNION 
#                 SELECT DISTINCT Txn_RefNo, Txn_Machine, Txn_MID, 0, 0, 0, 0, 0 
#                 FROM paytm_phonepe 
#                 WHERE Txn_RefNo IS NOT NULL AND Txn_RefNo != ''
#                 """
#                 cursor.execute(fallback_query)
#                 rows_inserted = cursor.rowcount
#                 print(f"   Fallback inserted: {rows_inserted} records")

#             # Step 3: Update the Recon_Outcome table (YOUR ORIGINAL LOGIC - CORRECTED)
#             print("3️ Updating Recon_Outcome with amounts...")
            
#             update_queries = [
#                 # PTPP Payment - Your original logic
#                 """UPDATE Recon_Outcome ro 
#                    SET PTPP_Payment = (SELECT COALESCE(SUM(pp.Txn_Amount), 0) 
#                    FROM reconciliation.paytm_phonepe pp 
#                    WHERE pp.Txn_Type = 'PAYMENT' AND pp.Txn_RefNo = ro.Txn_RefNo)""",
                
#                 # PTPP Refund - Your original logic  
#                 """UPDATE Recon_Outcome ro 
#                    SET PTPP_Refund = (SELECT COALESCE(SUM(pp.Txn_Amount), 0) 
#                    FROM reconciliation.paytm_phonepe pp 
#                    WHERE pp.Txn_Type = 'REFUND' AND pp.Txn_RefNo = ro.Txn_RefNo)""",
                
#                 # Cloud Payment - Your original logic
#                 """UPDATE Recon_Outcome ro 
#                    SET Cloud_Payment = (SELECT COALESCE(SUM(pr.Txn_Amount), 0) 
#                    FROM reconciliation.payment_refund pr 
#                    WHERE pr.Txn_RefNo = ro.Txn_RefNo 
#                    AND pr.Txn_Source = 'iCLOUD-PAYMENT' 
#                    AND (pr.Txn_Type = 'UPI / Wallet (Paytm)' 
#                         OR pr.Txn_Type = 'UPI / Wallet / Card (PhonePe)'))""",
                
#                 # Cloud Refund - Your original logic
#                 """UPDATE Recon_Outcome ro 
#                    SET Cloud_Refund = (SELECT COALESCE(SUM(pr.Txn_Amount), 0) 
#                    FROM reconciliation.payment_refund pr 
#                    WHERE pr.Txn_Source = 'iCLOUD-REFUND' 
#                    AND pr.Txn_Type != ' (manual)' 
#                    AND pr.Txn_RefNo = ro.Txn_RefNo)""",
                
#                 # Cloud Manual Refund - Your original logic
#                 """UPDATE Recon_Outcome ro 
#                    SET Cloud_MRefund = (SELECT COALESCE(SUM(pr.Txn_Amount), 0) 
#                    FROM reconciliation.payment_refund pr 
#                    WHERE pr.Txn_RefNo = ro.Txn_RefNo 
#                    AND pr.Txn_Source = 'iCLOUD-REFUND' 
#                    AND pr.Txn_Type = ' (manual)')"""
#             ]

#             # Execute the update queries
#             for i, query in enumerate(update_queries, 1):
#                 cursor.execute(query)
#                 affected_rows = cursor.rowcount
#                 print(f"   Update query {i}: {affected_rows} rows affected")
                
#                 # If no rows affected, show what data exists
#                 if affected_rows == 0 and i == 1:  # Check on first query
#                     print(f"    Debugging: Checking actual Txn_Types in paytm_phonepe...")
#                     cursor.execute("SELECT DISTINCT Txn_Type FROM paytm_phonepe LIMIT 10")
#                     actual_types = [row[0] for row in cursor.fetchall()]
#                     print(f"   Actual Txn_Types: {actual_types}")

#             # Commit the changes to the database
#             connection.commit()
#             print("4️ All changes committed to database.")

#             # Step 4: Show final results
#             print("5️ Final verification:")
#             cursor.execute("""
#                 SELECT 
#                     COUNT(*) as total,
#                     SUM(CASE WHEN PTPP_Payment > 0 THEN 1 ELSE 0 END) as ptpp_pay,
#                     SUM(CASE WHEN PTPP_Refund > 0 THEN 1 ELSE 0 END) as ptpp_ref,
#                     SUM(CASE WHEN Cloud_Payment > 0 THEN 1 ELSE 0 END) as cloud_pay,
#                     SUM(CASE WHEN Cloud_Refund > 0 THEN 1 ELSE 0 END) as cloud_ref,
#                     SUM(CASE WHEN Cloud_MRefund > 0 THEN 1 ELSE 0 END) as cloud_manual
#                 FROM Recon_Outcome
#             """)
            
#             stats = cursor.fetchone()
#             print(f"    Total records: {stats[0]}")
#             print(f"    PTPP Payments: {stats[1]}")
#             print(f"    PTPP Refunds: {stats[2]}")
#             print(f"    Cloud Payments: {stats[3]}")
#             print(f"    Cloud Refunds: {stats[4]}")
#             print(f"    Cloud Manual Refunds: {stats[5]}")
            
#             # Show sample results
#             cursor.execute("SELECT * FROM Recon_Outcome WHERE (PTPP_Payment + PTPP_Refund + Cloud_Payment + Cloud_Refund + Cloud_MRefund) > 0 LIMIT 3")
#             samples = cursor.fetchall()
#             if samples:
#                 print(f"    Sample populated records:")
#                 for row in samples:
#                     print(f"      {row}")
            
#             print(" All SQL commands executed successfully!")

#     except Error as e:
#         print(f" Database Error: {e}")
#         if connection:
#             connection.rollback()
#     except Exception as e:
#         print(f" Error: {e}")
#         if connection:
#             connection.rollback()
#     finally:
#         # Close the database connection
#         if connection and connection.is_connected():
#             cursor.close()
#             connection.close()
#             print(" MySQL connection closed.")

# # Call the function to execute the SQL commands
# if __name__ == "__main__":
#     execute_sql_commands()


#6


import mysql.connector
from mysql.connector import Error

# Function to execute the SQL commands
def execute_sql_commands():
    try:
        # Connect to the MySQL database
        connection = mysql.connector.connect(
            host='localhost',  # Replace with your host
            database='reconciliation',  # Replace with your database name
            user='root',  # Replace with your username
            password='Templerun@2'  # Replace with your password
        )

        if connection.is_connected():
            cursor = connection.cursor()
            
            # Start by clearing the Recon_Outcome table
            delete_query = "DELETE FROM Recon_Outcome;"
            cursor.execute(delete_query)
            print("Deleted records from Recon_Outcome.")

            # Insert new records into Recon_Outcome
            insert_query = """
            INSERT INTO Recon_Outcome (Txn_RefNo, Txn_Machine, Txn_MID, PTPP_Payment, PTPP_Refund, Cloud_Payment, Cloud_Refund, Cloud_MRefund)
            (SELECT DISTINCT Txn_RefNo, Txn_Machine, Txn_MID, 0, 0, 0, 0, 0 
            FROM payment_refund pr 
            WHERE (left(pr.Txn_Source,6) = 'iCLOUD') 
            AND ((left(pr.Txn_Type,3) = 'UPI') OR (pr.Txn_Type = ' (manual)')))
            UNION 
            (SELECT DISTINCT Txn_RefNo, Txn_Machine, Txn_MID, 0, 0, 0, 0, 0 
            FROM paytm_phonepe pp);
            """
            cursor.execute(insert_query)
            print("Inserted new records into Recon_Outcome.")

            # Update the Recon_Outcome table
            update_queries = [
                """UPDATE Recon_Outcome RO 
                   SET PTPP_Payment = (SELECT COALESCE(SUM(pp.Txn_Amount), 0) 
                   FROM reconciliation.paytm_phonepe pp 
                   WHERE pp.Txn_Type = 'PAYMENT' AND pp.Txn_RefNo = ro.Txn_RefNo);""",
                """UPDATE Recon_Outcome RO 
                   SET PTPP_Refund = (SELECT COALESCE(SUM(pp.Txn_Amount), 0) 
                   FROM reconciliation.paytm_phonepe pp 
                   WHERE pp.Txn_Type = 'REFUND' AND pp.Txn_RefNo = ro.Txn_RefNo);""",
                """UPDATE Recon_Outcome RO 
                   SET Cloud_Payment = (SELECT COALESCE(SUM(pr.Txn_Amount), 0) 
                   FROM reconciliation.payment_refund pr 
                   WHERE pr.Txn_RefNo = ro.Txn_RefNo 
                   AND pr.Txn_Source = 'iCLOUD-PAYMENT' 
                   AND (pr.Txn_Type = 'UPI / Wallet (Paytm)' 
                   OR pr.Txn_Type = 'UPI / Wallet / Card (PhonePe)'));""",
                """UPDATE Recon_Outcome RO 
                   SET Cloud_Refund = (SELECT COALESCE(SUM(pr.Txn_Amount), 0) 
                   FROM reconciliation.payment_refund pr 
                   WHERE pr.Txn_Source = 'iCLOUD-REFUND' 
                   AND pr.Txn_Type != ' (manual)' 
                   AND pr.Txn_RefNo = ro.Txn_RefNo);""",
                """UPDATE Recon_Outcome RO 
                   SET Cloud_MRefund = (SELECT COALESCE(SUM(pr.Txn_Amount), 0) 
                   FROM reconciliation.payment_refund pr 
                   WHERE pr.Txn_RefNo = ro.Txn_RefNo 
                   AND pr.Txn_Source = 'iCLOUD-REFUND' 
                   AND pr.Txn_Type = ' (manual)');""",
            ]

            # Execute the update queries
            for query in update_queries:
                cursor.execute(query)
                print(f"Executed update query: {query[:50]}...")  # Print the first 50 characters of each query for confirmation

            # Commit the changes to the database
            connection.commit()
            print("All SQL commands executed successfully.")

    except Error as e:
        print(f"Error: {e}")
    finally:
        # Close the database connection
        if connection.is_connected():
            cursor.close()
            connection.close()
            print("MySQL connection is closed.")

# Call the function to execute the SQL commands
execute_sql_commands()