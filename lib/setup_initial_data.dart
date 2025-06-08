import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<bool> isAlreadySetup() async {
    try {
      final adminDoc = await _firestore.collection('users').doc('admin001').get();
      return adminDoc.exists;
    } catch (e) {
      return false;
    }
  }

  static Future<void> setupCompleteDatabase() async {
    try {
      // Check if already setup
      if (await isAlreadySetup()) {
        print('✅ Database already initialized');
        return;
      }

      print('🚀 Starting database initialization...');
      
      // Setup admin user
      await _setupAdminUser();
      
      // Setup default settings
      await _setupAdminSettings();
      
      // Setup sample users for testing
      await _setupSampleUsers();
      
      // Setup sample clients for testing
      await _setupSampleClients();
      
      // Setup collections indexes (for better performance)
      await _setupIndexes();
      
      print('✅ Database initialization completed successfully!');
      print('📱 Login credentials:');
      print('   Admin: admin / admin123');
      print('   User: testuser / test123');
      print('   Agency: testagency / test123');
      
    } catch (e) {
      print('❌ Database setup failed: $e');
      rethrow;
    }
  }

  static Future<void> _setupAdminUser() async {
    print('👤 Creating admin user...');
    
    await _firestore.collection('users').doc('admin001').set({
      "id": "admin001",
      "username": "admin",
      "password": _hashPassword("admin123"),
      "role": "admin",
      "name": "المدير العام",
      "phone": "966501234567",
      "email": "admin@example.com",
      "isActive": true,
      "isFrozen": false,
      "createdAt": DateTime.now().millisecondsSinceEpoch,
      "createdBy": "system"
    });
  }

  static Future<void> _setupAdminSettings() async {
    print('⚙️ Setting up default configurations...');
    
    await _firestore.collection('adminSettings').doc('config').set({
      "clientStatusSettings": {
        "greenDays": 30,
        "yellowDays": 30,
        "redDays": 1
      },
      "clientNotificationSettings": {
        "firstTier": {
          "days": 10, 
          "frequency": 2, 
          "message": "تنبيه: تنتهي تأشيرة العميل {clientName} خلال 10 أيام"
        },
        "secondTier": {
          "days": 5, 
          "frequency": 4, 
          "message": "تحذير: تنتهي تأشيرة العميل {clientName} خلال 5 أيام"
        },
        "thirdTier": {
          "days": 2, 
          "frequency": 8, 
          "message": "عاجل: تنتهي تأشيرة العميل {clientName} خلال يومين"
        }
      },
      "userNotificationSettings": {
        "firstTier": {
          "days": 10, 
          "frequency": 1, 
          "message": "تنبيه: ينتهي حسابك خلال 10 أيام"
        },
        "secondTier": {
          "days": 5, 
          "frequency": 1, 
          "message": "تحذير: ينتهي حسابك خلال 5 أيام"
        },
        "thirdTier": {
          "days": 2, 
          "frequency": 1, 
          "message": "عاجل: ينتهي حسابك خلال يومين"
        }
      },
      "whatsappMessages": {
        "clientMessage": "عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك قريباً. يرجى التواصل معنا.",
        "userMessage": "تنبيه: ينتهي حسابك قريباً. يرجى التجديد."
      },
      "systemSettings": {
        "autoFreeze": true,
        "notificationsEnabled": true,
        "backgroundServiceEnabled": true,
        "lastUpdated": DateTime.now().millisecondsSinceEpoch
      }
    });
  }

  static Future<void> _setupSampleUsers() async {
    print('👥 Creating sample users for testing...');
    
    final now = DateTime.now();
    final validationEnd = now.add(Duration(days: 90));
    
    // Sample regular user
    await _firestore.collection('users').doc('user001').set({
      "id": "user001",
      "username": "testuser",
      "password": _hashPassword("test123"),
      "role": "user",
      "name": "محمد أحمد",
      "phone": "966551234567",
      "email": "user@example.com",
      "isActive": true,
      "isFrozen": false,
      "validationEndDate": validationEnd.millisecondsSinceEpoch,
      "createdAt": now.millisecondsSinceEpoch,
      "createdBy": "admin001"
    });
    
    // Sample agency user
    await _firestore.collection('users').doc('agency001').set({
      "id": "agency001",
      "username": "testagency",
      "password": _hashPassword("test123"),
      "role": "agency",
      "name": "وكالة النور للسفر",
      "phone": "966551234568",
      "email": "agency@example.com",
      "isActive": true,
      "isFrozen": false,
      "validationEndDate": validationEnd.millisecondsSinceEpoch,
      "createdAt": now.millisecondsSinceEpoch,
      "createdBy": "admin001"
    });
  }

  static Future<void> _setupSampleClients() async {
    print('📋 Creating sample clients for testing...');
    
    final now = DateTime.now();
    final entryDate = now.subtract(Duration(days: 20)); // 70 days remaining
    final criticalEntryDate = now.subtract(Duration(days: 87)); // 3 days remaining
    
    // Sample client with good status
    await _firestore.collection('clients').doc('client001').set({
      "id": "client001",
      "clientName": "عبدالله محمد السعدي",
      "clientPhone": "966551111111",
      "phoneCountry": "saudi",
      "visaType": "umrah",
      "agentName": "أحمد الوكيل",
      "agentPhone": "966552222222",
      "entryDate": entryDate.millisecondsSinceEpoch,
      "notes": "عميل مميز - تجديد التأشيرة",
      "status": "green",
      "daysRemaining": 70,
      "hasExited": false,
      "createdBy": "user001",
      "createdAt": now.millisecondsSinceEpoch,
      "updatedAt": now.millisecondsSinceEpoch
    });
    
    // Sample client with critical status
    await _firestore.collection('clients').doc('client002').set({
      "id": "client002",
      "clientName": "فاطمة أحمد اليمني",
      "clientPhone": "967771111111",
      "phoneCountry": "yemen",
      "visaType": "visit",
      "agentName": "",
      "agentPhone": "",
      "entryDate": criticalEntryDate.millisecondsSinceEpoch,
      "notes": "تحتاج متابعة عاجلة",
      "status": "red",
      "daysRemaining": 3,
      "hasExited": false,
      "createdBy": "agency001",
      "createdAt": now.millisecondsSinceEpoch,
      "updatedAt": now.millisecondsSinceEpoch
    });
    
    // Sample exited client
    await _firestore.collection('clients').doc('client003').set({
      "id": "client003",
      "clientName": "سعد عبدالرحمن",
      "clientPhone": "966553333333",
      "phoneCountry": "saudi",
      "visaType": "hajj",
      "agentName": "مكتب الرحمة",
      "agentPhone": "966554444444",
      "entryDate": now.subtract(Duration(days: 30)).millisecondsSinceEpoch,
      "notes": "أكمل الحج بنجاح",
      "status": "white",
      "daysRemaining": 60,
      "hasExited": true,
      "createdBy": "user001",
      "createdAt": now.millisecondsSinceEpoch,
      "updatedAt": now.millisecondsSinceEpoch
    });
  }

  static Future<void> _setupIndexes() async {
    print('📊 Setting up database indexes...');
    
    // Note: Firestore indexes are usually created automatically
    // or through Firebase Console. This is just a placeholder
    // for any manual index creation if needed.
    
    // Create some sample notifications for testing
    final now = DateTime.now();
    
    await _firestore.collection('notifications').doc('notif001').set({
      "id": "notif001",
      "type": "clientExpiring",
      "title": "تنبيه انتهاء تأشيرة",
      "message": "تنتهي تأشيرة العميل فاطمة أحمد اليمني خلال 3 أيام",
      "targetUserId": "agency001",
      "clientId": "client002",
      "isRead": false,
      "priority": "high",
      "createdAt": now.millisecondsSinceEpoch
    });
    
    await _firestore.collection('notifications').doc('notif002').set({
      "id": "notif002",
      "type": "userValidationExpiring",
      "title": "تنبيه انتهاء صلاحية الحساب",
      "message": "ينتهي حسابك خلال 90 يوم",
      "targetUserId": "user001",
      "isRead": false,
      "priority": "low",
      "createdAt": now.millisecondsSinceEpoch
    });
  }

  static Future<void> resetDatabase() async {
    print('🗑️ Resetting database...');
    
    try {
      // Delete all collections (use with caution!)
      final collections = ['users', 'clients', 'notifications', 'adminSettings', 'userSettings'];
      
      for (String collection in collections) {
        final querySnapshot = await _firestore.collection(collection).get();
        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          await doc.reference.delete();
        }
      }
      
      print('✅ Database reset completed');
      
      // Re-setup after reset
      await setupCompleteDatabase();
      
    } catch (e) {
      print('❌ Database reset failed: $e');
      rethrow;
    }
  }
}
