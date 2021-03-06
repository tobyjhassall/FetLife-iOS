//
//  FLAppDelegate.m
//  FetLife
//
//  Created by Shawn Stricker on 8/20/11.
//  Copyright (c) 2011 KB1IBT.com. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "FLAppDelegate.h"

#import "FLMasterViewController.h"

#import "FLDetailViewController.h"

#import "FLNetworkController.h"
#import "FLConversations.h"
#import "FLUsers.h"
#import "FLMessages.h"

@implementation FLAppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize navigationController = _navigationController;
@synthesize splitViewController = _splitViewController;
@synthesize tabBarController = _tabBarController;
@synthesize fetlifeURL = _fetlifeURL;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.tabBarController = [[UITabBarController alloc] init];

    //RESTKIT
    [RKObjectManager objectManagerWithBaseURLString:@"https://fetlife.com/"];
    [[RKClient sharedClient].requestQueue setShowsNetworkActivityIndicatorWhenBusy:YES];
    [RKObjectMapping addDefaultDateFormatterForString:@"yyyy/MM/dd HH:mm:ss Z" inTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    RKManagedObjectStore *objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"FetLife.sqlite"];
    RKManagedObjectMapping *userMapping = [RKManagedObjectMapping mappingForClass:[FLUsers class] inManagedObjectStore:objectStore];
   [userMapping mapAttributes:@"id", @"nickname", @"profile_url",@"age",@"gender",@"role",@"location",@"pictures_url",@"videos_url",@"posts_url",@"medium_avatar_url",@"mini_avatar_url",@"small_avatar_url",nil];
    RKManagedObjectMapping *messagesMapping = [RKManagedObjectMapping mappingForClass:[FLMessages class] inManagedObjectStore:objectStore];
    [messagesMapping mapAttributes:@"id", @"body", @"created_at",@"stripped_body",nil];
    [messagesMapping hasOne:@"sender" withMapping:userMapping];
    RKManagedObjectMapping *conversationMapping = [RKManagedObjectMapping mappingForClass:[FLConversations class] inManagedObjectStore:objectStore];
    [conversationMapping mapKeyPath:@"id" toAttribute:@"id"];
    [conversationMapping mapKeyPath:@"subject" toAttribute:@"subject"];
    [conversationMapping mapKeyPath:@"archived" toAttribute:@"archived"];
    [conversationMapping mapKeyPath:@"archive_url" toAttribute:@"archive_url"];
    [conversationMapping mapKeyPath:@"delete_url" toAttribute:@"delete_url"];
    [conversationMapping mapKeyPath:@"deletion_token" toAttribute:@"deletion_token"];
    [conversationMapping hasOne:@"with_user" withMapping:userMapping];
    RKObjectRelationshipMapping* conversationMessageMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"messages" toKeyPath:@"messages" withMapping:messagesMapping];
    [conversationMapping addRelationshipMapping:conversationMessageMapping];
//    [conversationMapping hasMany:@"messages" withMapping:messagesMapping];
    [[RKObjectManager sharedManager].mappingProvider setMapping:conversationMapping forKeyPath:@"conversations"];
    [[RKObjectManager sharedManager].mappingProvider setObjectMapping:conversationMapping forResourcePathPattern:@"/conversations/:id"];
    [[[RKObjectManager sharedManager] router] routeClass:[FLConversations class] toResourcePath:@"/conversations/:id"];

    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        FLMasterViewController *masterViewController = [[FLMasterViewController alloc] init];
        self.navigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
        self.tabBarController.viewControllers = [NSArray arrayWithObjects:self.navigationController,nil];
        self.window.rootViewController = self.tabBarController;
        masterViewController.managedObjectContext = self.managedObjectContext;
    } else {
        FLMasterViewController *masterViewController = [[FLMasterViewController alloc] init];
        UINavigationController *masterNavigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
        
        FLDetailViewController *detailViewController = [[FLDetailViewController alloc] initWithNibName:@"FLDetailViewController_iPad" bundle:nil];
        UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:detailViewController];
    	
        self.splitViewController = [[UISplitViewController alloc] init];
        self.splitViewController.delegate = detailViewController;
        self.splitViewController.viewControllers = [NSArray arrayWithObjects:masterNavigationController, detailNavigationController, nil];
        
        self.tabBarController.viewControllers = [NSArray arrayWithObjects:self.splitViewController,nil];
        self.window.rootViewController = self.tabBarController;
        masterViewController.detailViewController = detailViewController;
        masterViewController.managedObjectContext = self.managedObjectContext;
    }
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"FetLife" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"FetLife.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: */
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];/*
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
