import mysql.connector
import pandas as pd
from pathlib import Path
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def get_db_config():
    """Get database configuration"""
    return {
        'host': os.getenv('DB_HOST', 'localhost'),
        'user': os.getenv('DB_USER', 'root'),
        'password': os.getenv('DB_PASSWORD', 'Templerun@2'),
        'database': os.getenv('DB_DATABASE', 'reconciliation'),
        'port': int(os.getenv('DB_PORT', 3306))
    }

def diagnose_recon_data():
    """Diagnose why reconciliation queries return no data"""
    try:
        # Connect to MySQL
        conn = mysql.connector.connect(**get_db_config())
        cursor = conn.cursor(dictionary=True)
        
        print("🔍 DIAGNOSING RECONCILIATION DATA")
        print("=" * 50)
        
        # 1. Check total records in recon_outcome
        cursor.execute("SELECT COUNT(*) as total FROM recon_outcome")
        total = cursor.fetchone()['total']
        print(f"📊 Total records in recon_outcome: {total}")
        
        # 2. Check sample data structure
        cursor.execute("SELECT * FROM recon_outcome LIMIT 5")
        sample_data = cursor.fetchall()
        print(f"\n📄 Sample recon_outcome data:")
        for i, row in enumerate(sample_data, 1):
            print(f"   {i}. Txn_RefNo: {row['Txn_RefNo']}")
            print(f"      Txn_MID: {row['Txn_MID']}")
            print(f"      PTPP: {row['PTPP_Payment']} + {row['PTPP_Refund']} = {float(row['PTPP_Payment']) + float(row['PTPP_Refund'])}")
            print(f"      Cloud: {row['Cloud_Payment']} + {row['Cloud_Refund']} + {row['Cloud_MRefund']} = {float(row['Cloud_Payment']) + float(row['Cloud_Refund']) + float(row['Cloud_MRefund'])}")
            print()
        
        # 3. Check for perfect matches
        perfect_query = """
        SELECT COUNT(*) as count 
        FROM recon_outcome ro1 
        WHERE (ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)
        """
        cursor.execute(perfect_query)
        perfect_count = cursor.fetchone()['count']
        print(f"✅ Perfect matches: {perfect_count}")
        
        # 4. Check for investigate cases
        investigate_query = """
        SELECT COUNT(*) as count 
        FROM recon_outcome ro1 
        WHERE (ro1.PTPP_Payment + ro1.PTPP_Refund) != (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)
        """
        cursor.execute(investigate_query)
        investigate_count = cursor.fetchone()['count']
        print(f"🔍 Investigate cases: {investigate_count}")
        
        # 5. Check for manual refunds by different criteria
        print(f"\n🔍 MANUAL REFUND ANALYSIS:")
        
        # Check what's actually in Txn_MID field
        cursor.execute("SELECT DISTINCT Txn_MID FROM recon_outcome LIMIT 10")
        mid_samples = cursor.fetchall()
        print(f"📋 Sample Txn_MID values:")
        for row in mid_samples:
            print(f"   '{row['Txn_MID']}'")
        
        # Check various manual patterns
        manual_patterns = [
            "WHERE ro.txn_mid like '%manual%'",
            "WHERE ro.txn_mid like '%Manual%'", 
            "WHERE ro.txn_mid like '%MANUAL%'",
            "WHERE ro.txn_mid like '%refund%'",
            "WHERE ro.txn_mid like '%Auto refund%'"
        ]
        
        for pattern in manual_patterns:
            query = f"SELECT COUNT(*) as count FROM recon_outcome ro {pattern}"
            cursor.execute(query)
            count = cursor.fetchone()['count']
            print(f"   {pattern}: {count} records")
        
        # 6. Check if the issue is with the subquery
        print(f"\n🔍 SUBQUERY ANALYSIS:")
        subquery_test = """
        SELECT COUNT(*) as count 
        FROM recon_outcome ro1 
        WHERE ro1.Txn_RefNo NOT IN (
            SELECT ro2.txn_refno FROM recon_outcome ro2 WHERE ro2.txn_mid like '%manual%'
        )
        """
        cursor.execute(subquery_test)
        subquery_count = cursor.fetchone()['count']
        print(f"   Records NOT matching '%manual%': {subquery_count}")
        
        # 7. Test the actual RECON_SUCCESS query
        print(f"\n🔍 TESTING ACTUAL QUERIES:")
        
        recon_success_query = """
        SELECT COUNT(*) as count 
        FROM recon_outcome ro1 
        WHERE ((ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)) 
        AND ro1.Txn_RefNo NOT IN (SELECT ro2.txn_refno FROM recon_outcome ro2 WHERE ro2.txn_mid like '%manual%')
        """
        cursor.execute(recon_success_query)
        success_count = cursor.fetchone()['count']
        print(f"   RECON_SUCCESS count: {success_count}")
        
        # 8. Test without the subquery filter
        simple_success_query = """
        SELECT COUNT(*) as count 
        FROM recon_outcome ro1 
        WHERE (ro1.PTPP_Payment + ro1.PTPP_Refund) = (ro1.Cloud_Payment + ro1.Cloud_Refund + ro1.Cloud_MRefund)
        """
        cursor.execute(simple_success_query)
        simple_success_count = cursor.fetchone()['count']
        print(f"   Simple perfect matches (no manual filter): {simple_success_count}")
        
        print(f"\n💡 RECOMMENDATIONS:")
        if perfect_count > 0 and success_count == 0:
            print("   ❌ The manual refund filter is removing all perfect matches")
            print("   🔧 Suggest: Remove or modify the manual refund filter")
        elif perfect_count == 0:
            print("   ❌ No perfect matches found in data")
            print("   🔧 Suggest: Check data quality and reconciliation logic")
        else:
            print("   ✅ Queries should be working - check Excel generation")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    diagnose_recon_data()