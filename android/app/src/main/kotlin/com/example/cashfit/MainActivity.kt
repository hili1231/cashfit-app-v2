package com.example.cashfit

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        configureFirestore()
    }

    private fun configureFirestore() {
        val firestore = FirebaseFirestore.getInstance()
        val settings =
                FirebaseFirestoreSettings.Builder()
                        .setPersistenceEnabled(true) // optional
                        .build()
        firestore.firestoreSettings = settings
    }
}
