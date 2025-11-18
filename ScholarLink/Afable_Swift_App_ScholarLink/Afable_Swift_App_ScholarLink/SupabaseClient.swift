//
//  supabaseClient.swift
//  Afable_Swift_App_ScholarLink
//
//  Created by STUDENT on 10/24/25.
//

import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://cfmgcyofjnjslgkmcwpu.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmbWdjeW9mam5qc2xna21jd3B1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyODM0ODMsImV4cCI6MjA3Njg1OTQ4M30.l9RM0uciyBfxZ0lAVcxLdh_Fe0U-eFhiApfsvKrfPj8"
        )
    }
}
