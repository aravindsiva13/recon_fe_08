# import mysql.connector
# import pandas as pd

# # MySQL connection details
# #host='localhost',  # e.g., localhost or an IP address
# #user='root',  # e.g., root
# #password='Riota@123',  # your MySQL password
# #database='reconciliation'  # the database you're using

# conn = mysql.connector.connect(
# host='localhost',  # e.g., localhost or an IP address
# user='root',  # e.g., root
# password='Templerun@2',  # your MySQL password
# database='reconciliation'  # the database you're using
# )
# # Queries to extract data
# queries = {
#     'SUMMARY': '(SELECT txn_source, Txn_type, sum(Txn_Amount) FROM reconciliation.payment_refund pr GROUP BY 1, 2) UNION (SELECT Txn_Source, Txn_type, sum(Txn_Amount) FROM reconciliation.paytm_phonepe pp GROUP BY 1, 2);',
#     'RAWDATA': '(SELECT * FROM reconciliation.paytm_phonepe pp) UNION ALL (SELECT * FROM reconciliation.payment_refund pr);', 
#     'RECON_SUCCESS': 'SELECT *, IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),"Perfect", "Investigate") AS Remarks FROM reconciliation.recon_outcome ro1 WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like \'%manual%\') ORDER BY 1;',
#     'RECON_INVESTIGATE': 'SELECT *, IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),"Perfect", "Investigate") AS Remarks FROM reconciliation.recon_outcome ro1 WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) != (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like \'%manual%\') ORDER BY 1;',
#    'MANUAL_REFUND': 'SELECT *, IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),"Perfect", "Investigate") AS Remarks FROM reconciliation.recon_outcome ro1 WHERE ro1.Txn_RefNo IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like \'%manual%\') ORDER BY 1;'
# }

# # Connect to MySQL


# # Create a Pandas ExcelWriter to write multiple sheets
# output_file = 'recon_output.xlsx'
# with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
#     for sheet_name, query in queries.items():
#         # Execute the query
#         df = pd.read_sql(query, conn)
        
#         # Write the dataframe to an Excel sheet
#         df.to_excel(writer, sheet_name=sheet_name, index=False)

# # Close the MySQL connection
# conn.close()

# print(f"Data has been successfully written to {output_file}.")	

#2

# import mysql.connector
# import pandas as pd
# import warnings
# import os
# from dotenv import load_dotenv

# # Suppress pandas warnings
# warnings.filterwarnings('ignore', category=UserWarning, module='pandas')

# # Load environment variables
# load_dotenv()

# def get_db_config():
#     """Get database configuration"""
#     return {
#         'host': os.getenv('DB_HOST', 'localhost'),
#         'user': os.getenv('DB_USER', 'root'),
#         'password': os.getenv('DB_PASSWORD', 'Templerun@2'),
#         'database': os.getenv('DB_DATABASE', 'reconciliation'),
#         'port': int(os.getenv('DB_PORT', 3306))
#     }

# # FIXED: Updated queries without problematic manual refund filter
# queries = {
#     'SUMMARY': '''
#         (SELECT txn_source, Txn_type, sum(Txn_Amount) FROM reconciliation.payment_refund pr GROUP BY 1, 2) 
#         UNION 
#         (SELECT Txn_Source, Txn_type, sum(Txn_Amount) FROM reconciliation.paytm_phonepe pp GROUP BY 1, 2)
#     ''',
    
#     'RAWDATA': '''
#         (SELECT * FROM reconciliation.paytm_phonepe pp) 
#         UNION ALL 
#         (SELECT * FROM reconciliation.payment_refund pr)
#     ''',
    
#     # FIXED: Simplified RECON_SUCCESS without manual filter
#     'RECON_SUCCESS': '''
#         SELECT *, 
#                IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
#                   "Perfect", "Investigate") AS Remarks 
#         FROM reconciliation.recon_outcome ro1 
#         WHERE (ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)
#         ORDER BY ro1.Txn_RefNo
#     ''',
    
#     # FIXED: Simplified RECON_INVESTIGATE without manual filter  
#     'RECON_INVESTIGATE': '''
#         SELECT *, 
#                IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
#                   "Perfect", "Investigate") AS Remarks 
#         FROM reconciliation.recon_outcome ro1 
#         WHERE (ro1.PTPP_Payment + ro1.PTPP_Refund) != (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)
#         ORDER BY ro1.Txn_RefNo
#     ''',
    
#     # FIXED: Manual refund based on actual data patterns
#     'MANUAL_REFUND': '''
#         SELECT *, 
#                IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
#                   "Perfect", "Investigate") AS Remarks 
#         FROM reconciliation.recon_outcome ro1 
#         WHERE (ro1.Txn_MID LIKE '%Auto refund%' 
#                OR ro1.Txn_MID LIKE '%manual%' 
#                OR ro1.Txn_MID LIKE '%Manual%'
#                OR ro1.Cloud_MRefund != 0)
#         ORDER BY ro1.Txn_RefNo
#     '''
# }

# def main():
#     try:
#         print(" Starting reconciliation report generation...")
        
#         # Connect to MySQL
#         conn = mysql.connector.connect(**get_db_config())
#         print(" Database connection successful")
        
#         # Create output file
#         output_file = 'recon_output.xlsx'
        
#         # Create Excel writer
#         with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
#             total_sheets = 0
            
#             for sheet_name, query in queries.items():
#                 try:
#                     print(f" Processing {sheet_name}...")
                    
#                     # Execute the query
#                     df = pd.read_sql(query, conn)
                    
#                     # Write to Excel
#                     df.to_excel(writer, sheet_name=sheet_name, index=False)
                    
#                     print(f"    {sheet_name}: {len(df)} rows written")
#                     total_sheets += 1
                    
#                 except Exception as query_error:
#                     print(f"    Error in {sheet_name}: {query_error}")
#                     # Create error sheet
#                     error_df = pd.DataFrame({
#                         'Error': [f'Query failed: {str(query_error)}'],
#                         'Query': [query[:200] + '...' if len(query) > 200 else query]
#                     })
#                     error_df.to_excel(writer, sheet_name=sheet_name, index=False)
        
#         # Close connection
#         conn.close()
        
#         print(f" Successfully generated {output_file} with {total_sheets} sheets")
        
#         # Verify the file was created
#         if os.path.exists(output_file):
#             file_size = os.path.getsize(output_file)
#             print(f" File size: {file_size:,} bytes")
#         else:
#             print(" Output file was not created!")
            
#     except Exception as e:
#         print(f" Error: {e}")
#         import traceback
#         traceback.print_exc()

# if __name__ == "__main__":
#     main()


#3

# import mysql.connector
# import pandas as pd
# import warnings
# import os
# from dotenv import load_dotenv

# # Suppress pandas warnings
# warnings.filterwarnings('ignore', category=UserWarning, module='pandas')

# # Load environment variables
# load_dotenv()

# def get_db_config():
#     """Get database configuration"""
#     return {
#         'host': os.getenv('DB_HOST', 'localhost'),
#         'user': os.getenv('DB_USER', 'root'),
#         'password': os.getenv('DB_PASSWORD', 'Templerun@2'),
#         'database': os.getenv('DB_DATABASE', 'reconciliation'),
#         'port': int(os.getenv('DB_PORT', 3306))
#     }

# def main():
#     try:
#         print(" Starting reconciliation report generation...")
        
#         # MySQL connection using your exact original connection method
#         conn = mysql.connector.connect(
#             host='localhost',
#             user='root',
#             password='Templerun@2',
#             database='reconciliation'
#         )
#         print(" Database connection successful")
        
#         # YOUR EXACT ORIGINAL QUERIES - CORRECTED
#         queries = {
#             'SUMMARY': '''
#                 (SELECT txn_source, Txn_type, sum(Txn_Amount) FROM reconciliation.payment_refund pr GROUP BY 1, 2) 
#                 UNION 
#                 (SELECT Txn_Source, Txn_type, sum(Txn_Amount) FROM reconciliation.paytm_phonepe pp GROUP BY 1, 2)
#             ''',
            
#             'RAWDATA': '''
#                 (SELECT * FROM reconciliation.paytm_phonepe pp) 
#                 UNION ALL 
#                 (SELECT * FROM reconciliation.payment_refund pr)
#             ''',
            
#             'RECON_SUCCESS': '''
#                 SELECT *, 
#                        IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
#                           "Perfect", "Investigate") AS Remarks 
#                 FROM reconciliation.recon_outcome ro1 
#                 WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) 
#                 AND ro1.Txn_RefNo NOT IN (
#                     SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 
#                     WHERE ro2.txn_mid LIKE '%manual%'
#                 ) 
#                 ORDER BY 1
#             ''',
            
#             'RECON_INVESTIGATE': '''
#                 SELECT *, 
#                        IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
#                           "Perfect", "Investigate") AS Remarks 
#                 FROM reconciliation.recon_outcome ro1 
#                 WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) != (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) 
#                 AND ro1.Txn_RefNo NOT IN (
#                     SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 
#                     WHERE ro2.txn_mid LIKE '%manual%'
#                 ) 
#                 ORDER BY 1
#             ''',
            
#             'MANUAL_REFUND': '''
#                 SELECT *, 
#                        IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),
#                           "Perfect", "Investigate") AS Remarks 
#                 FROM reconciliation.recon_outcome ro1 
#                 WHERE ro1.Txn_RefNo IN (
#                     SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 
#                     WHERE ro2.txn_mid LIKE '%manual%'
#                 ) 
#                 ORDER BY 1
#             '''
#         }
        
#         # Create output file (your exact original method)
#         output_file = 'recon_output.xlsx'
        
#         # Create a Pandas ExcelWriter to write multiple sheets (your exact original method)
#         with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
#             total_sheets = 0
            
#             for sheet_name, query in queries.items():
#                 try:
#                     print(f" Processing {sheet_name}...")
                    
#                     # Execute the query (your exact original method)
#                     df = pd.read_sql(query, conn)
                    
#                     # Write the dataframe to an Excel sheet (your exact original method)
#                     df.to_excel(writer, sheet_name=sheet_name, index=False)
                    
#                     print(f"    {sheet_name}: {len(df)} rows written")
#                     total_sheets += 1
                    
#                 except Exception as query_error:
#                     print(f"    Error in {sheet_name}: {query_error}")
                    
#                     # Create error sheet with details
#                     error_df = pd.DataFrame({
#                         'Error': [f'Query failed: {str(query_error)}'],
#                         'Query': [query[:200] + '...' if len(query) > 200 else query]
#                     })
#                     error_df.to_excel(writer, sheet_name=sheet_name, index=False)
        
#         # Close the MySQL connection (your exact original method)
#         conn.close()
        
#         print(f" Successfully generated {output_file} with {total_sheets} sheets")
        
#         # Verify the file was created
#         if os.path.exists(output_file):
#             file_size = os.path.getsize(output_file)
#             print(f" File size: {file_size:,} bytes")
            
#             # Show summary of what was generated
#             print("\n Generated sheets:")
#             print("   - SUMMARY: Transaction summary by source and type")
#             print("   - RAWDATA: All raw transaction data")
#             print("   - RECON_SUCCESS: Perfect reconciliation matches")
#             print("   - RECON_INVESTIGATE: Transactions requiring investigation")
#             print("   - MANUAL_REFUND: Manual refund transactions")
            
#         else:
#             print(" Output file was not created!")
            
#     except Exception as e:
#         print(f" Error: {e}")
#         import traceback
#         traceback.print_exc()

# if __name__ == "__main__":
#     main()

#4


import mysql.connector
import pandas as pd

# MySQL connection details
conn = mysql.connector.connect(
    host='localhost',  # e.g., localhost or an IP address
    user='root',  # e.g., root
    password='Templerun@2',  # your MySQL password
    database='reconciliation'  # the database you're using
)

# Queries to extract data
queries = {
    'SUMMARY': '(SELECT txn_source, Txn_type, sum(Txn_Amount) FROM reconciliation.payment_refund pr GROUP BY 1, 2) UNION (SELECT Txn_Source, Txn_type, sum(Txn_Amount) FROM reconciliation.paytm_phonepe pp GROUP BY 1, 2);',
    'RAWDATA': '(SELECT * FROM reconciliation.paytm_phonepe pp) UNION ALL (SELECT * FROM reconciliation.payment_refund pr);', 
    'RECON_SUCCESS': 'SELECT *, IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),"Perfect", "Investigate") AS Remarks FROM reconciliation.recon_outcome ro1 WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like \'%manual%\') ORDER BY 1;',
    'RECON_INVESTIGATE': 'SELECT *, IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),"Perfect", "Investigate") AS Remarks FROM reconciliation.recon_outcome ro1 WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) != (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like \'%manual%\') ORDER BY 1;',
    'MANUAL_REFUND': 'SELECT *, IF((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund),"Perfect", "Investigate") AS Remarks FROM reconciliation.recon_outcome ro1 WHERE ro1.Txn_RefNo IN (SELECT ro2.txn_refno FROM reconciliation.recon_outcome ro2 WHERE ro2.txn_mid like \'%manual%\') ORDER BY 1;'
}

# Create a Pandas ExcelWriter to write multiple sheets
output_file = 'recon_output.xlsx'
with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
    for sheet_name, query in queries.items():
        # Execute the query
        df = pd.read_sql(query, conn)
        
        # Write the dataframe to an Excel sheet
        df.to_excel(writer, sheet_name=sheet_name, index=False)

# Close the MySQL connection
conn.close()

print(f"Data has been successfully written to {output_file}.")