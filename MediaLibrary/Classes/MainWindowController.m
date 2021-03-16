/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2014 Jean-David Gadina - www-xs-labs.com
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

#import "MainWindowController.h"
#import "Track.h"

@import iTunesLibrary;

@interface MainWindowController() < NSTableViewDelegate >

@property( atomic, readwrite, strong ) NSArray< Track    * > * allTracks;
@property( atomic, readwrite, strong ) NSArray< Track    * > * tracks;
@property( atomic, readwrite, strong ) NSArray< NSString * > * artists;
@property( atomic, readwrite, strong ) NSArray< NSString * > * albums;

@property( atomic, readwrite, strong ) IBOutlet NSArrayController * tracksController;
@property( atomic, readwrite, strong ) IBOutlet NSArrayController * artistsController;
@property( atomic, readwrite, strong ) IBOutlet NSArrayController * albumsController;

- ( NSArray< NSString * > * )uniqueValue: ( NSString * )keypath inArray: ( NSArray< Track * > * )array;

@end

@implementation MainWindowController

- ( id )init
{
    return [ super initWithWindowNibName: @"MainWindow" ];
}

- ( void )windowDidLoad
{
    NSError   * error;
    ITLibrary * library;
    NSString  * title;
    
    [ super windowDidLoad ];
    
    library = [ ITLibrary libraryWithAPIVersion: @"1.0" error: &error ];
    
    if( library == nil || error != nil )
    {
        NSLog( @"%@", error );
    }
    else
    {
        NSMutableArray< Track * > * tracks = [ NSMutableArray new ];
        
        for( ITLibMediaItem * item in library.allMediaItems )
        {
            [ tracks addObject: [ [ Track alloc ] initWithItem: item ] ];
        }
        
        self.allTracks = [ tracks copy ];
        self.tracks    = self.allTracks;
        self.artists   = [ self uniqueValue: @"artist" inArray: self.tracks ];
        self.albums    = [ self uniqueValue: @"album"  inArray: self.tracks ];
        
        [ self.artistsController setSortDescriptors: @[ [ NSSortDescriptor sortDescriptorWithKey: @"description" ascending: YES ] ] ];
        [ self.albumsController  setSortDescriptors: @[ [ NSSortDescriptor sortDescriptorWithKey: @"description" ascending: YES ] ] ];
        [ self.tracksController  setSortDescriptors:
            @[
                [ NSSortDescriptor sortDescriptorWithKey: @"artist" ascending: YES ],
                [ NSSortDescriptor sortDescriptorWithKey: @"album"  ascending: YES ],
                [ NSSortDescriptor sortDescriptorWithKey: @"title"  ascending: YES ]
            ]
        ];
        
        self.artistsController.selectionIndexes = [ NSIndexSet indexSet ];
        
        title             = [ self.window.title stringByAppendingString: [ NSString stringWithFormat: @" (%lu tracks)", self.allTracks.count ] ];
        self.window.title = title;
    }
}

- ( NSArray< NSString * > * )uniqueValue: ( NSString * )keypath inArray: ( NSArray< ITLibMediaItem * > * )array
{
    NSMutableSet   * set;
    ITLibMediaItem * media;
    NSString       * value;
    
    set = [ NSMutableSet new ];
    
    for( media in array )
    {
        @try
        {
            if( ( value = [ media valueForKeyPath: keypath ] ) && [ value isKindOfClass: [ NSString class ] ] )
            {
                [ set addObject: value ];
            }
        }
        @catch( NSException * e )
        {}
    }
    
    return set.allObjects;
}

- ( void )tableViewSelectionDidChange: ( NSNotification * )notification
{
    NSTableView * tableView;
    BOOL ( ^ artistFilter )( Track * track, NSDictionary * bindings );
    BOOL ( ^ albumFilter  )( Track * track, NSDictionary * bindings );
    
    tableView = ( NSTableView * )( notification.object );
    
    if( [ tableView isKindOfClass: [ NSTableView class ] ] == NO )
    {
        return;
    }
    
    artistFilter = ^ BOOL ( Track * track, NSDictionary * bindings )
    {
        ( void )bindings;
        
        if( self.artistsController.selectedObjects.count == 0 )
        {
            return YES;
        }
        
        for( NSString * artist in self.artistsController.selectedObjects )
        {
            if( [ track.artist isEqualToString: artist ] )
            {
                return YES;
            }
        }
        
        return NO;
    };
    
    albumFilter = ^ BOOL ( Track * track, NSDictionary * bindings )
    {
        ( void )bindings;
        
        if( self.albumsController.selectedObjects.count == 0 )
        {
            return YES;
        }
        
        for( NSString * album in self.albumsController.selectedObjects )
        {
            if( [ track.album isEqualToString: album ] )
            {
                return YES;
            }
        }
        
        return NO;
    };
    
    if( [ tableView.identifier isEqualToString: @"Artists" ] )
    {
        self.tracks = [ self.allTracks filteredArrayUsingPredicate: [ NSPredicate predicateWithBlock: artistFilter ] ];
        self.albums = [ self uniqueValue: @"album"  inArray: self.tracks ];
        
        self.albumsController.selectionIndexes = [ NSIndexSet indexSet ];
        self.tracksController.selectionIndexes = [ NSIndexSet indexSet ];
    }
    else if( [ tableView.identifier isEqualToString: @"Albums" ] )
    {
        self.tracks = [ self.allTracks filteredArrayUsingPredicate: [ NSPredicate predicateWithBlock: artistFilter ] ];
        self.tracks = [ self.tracks    filteredArrayUsingPredicate: [ NSPredicate predicateWithBlock: albumFilter ] ];
        
        self.tracksController.selectionIndexes = [ NSIndexSet indexSet ];
    }
}

@end
