//
//  WorkModel.swift
//  Workout
//
//  Created by Michele Manniello on 11/06/23.
//

import Foundation
import WorkoutKit
import HealthKit

class WorkModel {
    
   static public var shared = WorkModel()
    
    private let warmupStep = WarmupStep()
    
    private let block1: IntervalBlock = {
        
        var workStep1: BlockStep {
            let twoKilometers = HKQuantity(unit: .meter(), doubleValue: 2000)
            let twoKilometersGoal: WorkoutGoal = .distance(twoKilometers)
    //  alert for 10 miles for hour
            let paceUnit: HKUnit = .meter().unitDivided(by: .hour())
            let paceValue = HKQuantity(unit: paceUnit, doubleValue: 10)
            let paceTarget: WorkoutTargetType = .target(value: paceValue)
            let paceAlert = WorkoutAlert(type: .currentPace,
                                         target: paceTarget)
            return BlockStep(.work, goal: twoKilometersGoal, alert: paceAlert)
        }
        
        var recovery1: BlockStep {
            let halfMile = HKQuantity(unit: .meter(), doubleValue: 1000)
            let halfMileGoal: WorkoutGoal = .distance(halfMile)
            
    //        heart rate zone
            let heartRateAlert = WorkoutAlert(type: .currentHeartRate, target: .zone(zone: 1))
            
            return BlockStep(.rest, goal: halfMileGoal, alert: heartRateAlert)
        }
        
        return IntervalBlock(steps: [workStep1,recovery1], iterations: 4)
    }()
    
     private let block2: IntervalBlock = {
        
        var workStep: BlockStep {
            let twoMinutes = HKQuantity(unit: .minute(), doubleValue: 2)
            let twoMinuteGoal: WorkoutGoal = .time(twoMinutes)
            
            //        Power range alert for 250W - 275W
            
            let powerMinValue = HKQuantity(unit: .watt(), doubleValue: 250)
            let powerMaxValue = HKQuantity(unit: .watt(), doubleValue: 275)
            
            let powerRange: WorkoutTargetType = .range(min: powerMinValue, max: powerMaxValue)
            let powerAlert = WorkoutAlert(type: .currentPower, target: powerRange)
            
            return BlockStep(.work,goal: twoMinuteGoal,alert: powerAlert)
            
        }
        
        var recovery: BlockStep {
            let thirtySeconds = HKQuantity(unit: .second(), doubleValue: 30)
            let thirtySecondGoal: WorkoutGoal = .time(thirtySeconds)
            
            //    heart rate zone 1 alert
            let heartRateAlert = WorkoutAlert(type: .currentHeartRate, target: .zone(zone: 1))
            
            //        recovery steo
            return BlockStep(.rest, goal: thirtySecondGoal, alert: heartRateAlert)
            
        }
        
        return IntervalBlock(steps: [workStep,recovery], iterations: 2)
    }()
    
     private var cooldown: CooldownStep {
        let fiveMinutes = HKQuantity(unit: .minute(), doubleValue: 5)
        let fiveMinuteGoal: WorkoutGoal = .time(fiveMinutes)
        return CooldownStep(goal: fiveMinuteGoal)
    }
    
    public func createCyclingCustomComposition() -> CustomWorkoutComposition? {
        let cyclingActivity: HKWorkoutActivityType = .cycling
        let location: HKWorkoutSessionLocationType = .outdoor
        do {
          let customWorkoutComposition = try CustomWorkoutComposition(activity: cyclingActivity,
                                         location: location,
                                         displayName: "My Workout Cyclism",
                                         warmup: warmupStep,
                                         blocks: [block1, block2],
                                         cooldown: cooldown)
//            Validation and exporting
            return customWorkoutComposition
            
            
        } catch  {
            print(error.localizedDescription)
            return nil
        }
    }
    
    public func createRunningCustomComposition() -> CustomWorkoutComposition? {
        let runningActivity: HKWorkoutActivityType = .running
        let location: HKWorkoutSessionLocationType = .outdoor
        do {
          let customWorkoutComposition = try CustomWorkoutComposition(activity: runningActivity,
                                         location: location,
                                         displayName: "My Workout",
                                         warmup: warmupStep,
                                         blocks: [block1, block2],
                                         cooldown: cooldown)
//            Validation and exporting
            return customWorkoutComposition
            
            
        } catch  {
            print(error.localizedDescription)
            return nil
        }
    }
    
    
    
    
}

//Schedule Workout
struct WorkoutKitInterface {
    
   static var shared = WorkoutKitInterface()
    
    var workoutPlan = WorkoutPlan()
    
    func getAuthorizationState() async -> WorkoutPlan.AuthorizationState {
        do {
            return try await WorkoutPlan.authorizationState
        } catch  {
            return .undetermined
        }
    }
    
    func requestAuthorization() async -> WorkoutPlan.AuthorizationState  {
        do {
            return try await WorkoutPlan.requestAuthorization()
        } catch  {
            return .undetermined
        }
    }
    
    mutating func getCurrentWorkoutPlan() async throws {
        self.workoutPlan = try await WorkoutPlan.current
    }
    
    func scheduleWorkouts() -> [ScheduledWorkoutComposition] {
        var scheduledCompositions: [ScheduledWorkoutComposition] = []
        
//  Running day
        if let running = WorkModel.shared.createRunningCustomComposition() {
            let scheduleRunning = ScheduledWorkoutComposition(WorkoutComposition(customComposition: running) , scheduledDate: Date(timeIntervalSinceNow: 60 * 60))
            scheduledCompositions.append(scheduleRunning)
        }
        
//        Cycling day after tomorrow
        if let cycling = WorkModel.shared.createCyclingCustomComposition() {
            let scheduleCycling = ScheduledWorkoutComposition(WorkoutComposition(customComposition: cycling), scheduledDate: Date(timeIntervalSinceNow: 50 * 60 * 60))
            scheduledCompositions.append(scheduleCycling)
        }
        
        return scheduledCompositions
    }
    
    mutating func save() async throws {
        let scheduledWorkouts = scheduleWorkouts()
        workoutPlan.scheduledCompositions.append(contentsOf: scheduledWorkouts)
        try await workoutPlan.save()
    }
    
//    When schedule is complited
    func isWorkoutCompleted(_ scheduledComposition: ScheduledWorkoutComposition) -> Bool {
        return scheduledComposition.completed
    }
    
}
