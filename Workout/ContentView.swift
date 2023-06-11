//
//  ContentView.swift
//  Workout
//
//  Created by Michele Manniello on 11/06/23.
//

import SwiftUI
import WorkoutKit

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Workout")
                .font(.title)
                .padding()
            
            Button("Present Cycling Workout Preivew") {
                guard let cyclingWorkoutCompostion = WorkModel.shared.createCyclingCustomComposition() else { return }
                let workoutComposition = WorkoutComposition(customComposition: cyclingWorkoutCompostion)
                Task {
                   try await workoutComposition.presentPreview()
                }
            }
            #if !targetEnvironment(simulator)
            List {
                
                Section("Save to Watch") {
                    Button("Save") {
                        Task {
                            do {
                                try await WorkoutKitInterface.shared.save()
                            } catch {
                                print(error.localizedDescription)
                            }
                           
                        }
                        
                    }
                }
                
                Section("Fetch Form Watch") {
                    Button("Get Worokut Plan") {
                        Task {
                            try await WorkoutKitInterface.shared.getCurrentWorkoutPlan()
                        }
                    }
                }
                
                
                Section("Authorization") {
                    Button("Request Authorization") {
                        Task {
                            await WorkoutKitInterface.shared.getAuthorizationState()
                            try await WorkoutKitInterface.shared.requestAuthorization()
                        }
                    }
                }
                
                
                
            }
            #endif
        }
        .padding()
        
      
        
    }
}

#Preview {
    ContentView()
}
