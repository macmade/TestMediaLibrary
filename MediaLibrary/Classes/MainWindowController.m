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

@interface MainWindowController() < NSTableViewDelegate >

@property( atomic, readwrite, strong ) NSArray * allTracks;
@property( atomic, readwrite, strong ) NSArray * tracks;
@property( atomic, readwrite, strong ) NSArray * artists;
@property( atomic, readwrite, strong ) NSArray * albums;

@property( atomic, readwrite, strong ) IBOutlet NSArrayController * tracksController;
@property( atomic, readwrite, strong ) IBOutlet NSArrayController * artistsController;
@property( atomic, readwrite, strong ) IBOutlet NSArrayController * albumsController;

- ( NSArray * )uniqueValue: ( NSString * )key inArray: ( NSArray * )array;

@end

@implementation MainWindowController

- ( id )init
{
    return [ super initWithWindowNibName: @"MainWindow" ];
}

- ( void )windowDidLoad
{
    NSDictionary * library;
    NSString     * title;
    
    [ super windowDidLoad ];
    
    library        = [ NSDictionary dictionaryWithContentsOfFile: [ @"~/Music/iTunes/iTunes Music Library.xml" stringByStandardizingPath ] ];
    self.allTracks = ( ( NSDictionary * )library[ @"Tracks" ] ).allValues;
    self.tracks    = self.allTracks;
    self.artists   = [ self uniqueValue: @"Artist" inArray: self.tracks ];
    self.albums    = [ self uniqueValue: @"Album"  inArray: self.tracks ];
    
    [ self.artistsController setSortDescriptors: @[ [ NSSortDescriptor sortDescriptorWithKey: @"description" ascending: YES ] ] ];
    [ self.albumsController  setSortDescriptors: @[ [ NSSortDescriptor sortDescriptorWithKey: @"description" ascending: YES ] ] ];
    [ self.tracksController  setSortDescriptors:
        @[
            [ NSSortDescriptor sortDescriptorWithKey: @"Artist" ascending: YES ],
            [ NSSortDescriptor sortDescriptorWithKey: @"Album"  ascending: YES ],
            [ NSSortDescriptor sortDescriptorWithKey: @"Name"   ascending: YES ]
        ]
    ];
    
    self.artistsController.selectionIndexes = [ NSIndexSet indexSet ];
    
    title             = [ self.window.title stringByAppendingString: [ NSString stringWithFormat: @" (%lu tracks)", self.allTracks.count ] ];
    self.window.title = title;
}

- ( NSArray * )uniqueValue: ( NSString * )key inArray: ( NSArray * )array
{
    NSMutableSet * set;
    NSDictionary * dict;
    NSString     * value;
    
    set = [ NSMutableSet new ];
    
    for( dict in array )
    {
        if( ( value = dict[ key ] ) )
        {
            [ set addObject: value ];
        }
    }
    
    return set.allObjects;
}

- ( void )tableViewSelectionDidChange: ( NSNotification * )notification
{
    NSTableView * tableView;
    BOOL ( ^ artistFilter )( NSDictionary * track, NSDictionary * bindings );
    BOOL ( ^ albumFilter  )( NSDictionary * track, NSDictionary * bindings );
    
    tableView = ( NSTableView * )( notification.object );
    
    if( [ tableView isKindOfClass: [ NSTableView class ] ] == NO )
    {
        return;
    }
    
    artistFilter = ^ BOOL ( NSDictionary * track, NSDictionary * bindings )
    {
        ( void )bindings;
        
        if( self.artistsController.selectedObjects.count == 0 )
        {
            return YES;
        }
        
        for( NSString * artist in self.artistsController.selectedObjects )
        {
            if( [ track[ @"Artist" ] isEqualToString: artist ] )
            {
                return YES;
            }
        }
        
        return NO;
    };
    
    albumFilter = ^ BOOL ( NSDictionary * track, NSDictionary * bindings )
    {
        ( void )bindings;
        
        if( self.albumsController.selectedObjects.count == 0 )
        {
            return YES;
        }
        
        for( NSString * album in self.albumsController.selectedObjects )
        {
            if( [ track[ @"Album" ] isEqualToString: album ] )
            {
                return YES;
            }
        }
        
        return NO;
    };
    
    if( [ tableView.identifier isEqualToString: @"Artists" ] )
    {
        self.tracks = [ self.allTracks filteredArrayUsingPredicate: [ NSPredicate predicateWithBlock: artistFilter ] ];
        self.albums = [ self uniqueValue: @"Album"  inArray: self.tracks ];
        
        self.albumsController.selectionIndexes = [ NSIndexSet indexSet ];
        self.tracksController.selectionIndexes = [ NSIndexSet indexSet ];
    }
    else if( [ tableView.identifier isEqualToString: @"Albums" ] )
    {
        self.tracks = [ self.allTracks filteredArrayUsingPredicate: [ NSPredicate predicateWithBlock: artistFilter ] ];
        self.tracks = [ self.tracks filteredArrayUsingPredicate: [ NSPredicate predicateWithBlock: albumFilter ] ];
        
        self.tracksController.selectionIndexes = [ NSIndexSet indexSet ];
    }
}

@end
