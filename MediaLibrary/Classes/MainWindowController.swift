/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2021 Jean-David Gadina - www.xs-labs.com
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

import Cocoa
import iTunesLibrary

@objc class MainWindowController: NSWindowController, NSTableViewDelegate
{
    @IBOutlet private var tracksController:  NSArrayController!
    @IBOutlet private var artistsController: NSArrayController!
    @IBOutlet private var albumsController:  NSArrayController!
    
    @objc private dynamic var allTracks: [ Track ]  = []
    @objc private dynamic var tracks:    [ Track ]  = []
    @objc private dynamic var artists:   [ String ] = []
    @objc private dynamic var albums:    [ String ] = []
    
    override var windowNibName: NSNib.Name?
    {
        "MainWindowController"
    }
    
    override func windowDidLoad()
    {
        super.windowDidLoad()
        
        do
        {
            let library = try ITLibrary( apiVersion: "1.0" )
            
            self.allTracks = library.allMediaItems.map { Track( item: $0 ) }
            self.tracks    = self.allTracks
            self.artists   = self.uniqueValues( for: "artist", in: self.allTracks )
            self.albums    = self.uniqueValues( for: "album",  in: self.allTracks )
            
            self.artistsController.sortDescriptors = [ NSSortDescriptor( key: "description", ascending: true ) ]
            self.albumsController.sortDescriptors  = [ NSSortDescriptor( key: "description", ascending: true ) ]
            self.tracksController.sortDescriptors  =
            [
                NSSortDescriptor( key: "artist", ascending: true ),
                NSSortDescriptor( key: "album",  ascending: true ),
                NSSortDescriptor( key: "title",  ascending: true )
            ]
            
            if let window = self.window
            {
                window.title = "\( window.title ) \( self.allTracks.count ) tracks"
            }
        }
        catch let error
        {
            NSAlert( error: error ).runModal()
        }
    }
    
    private func uniqueValues( for key: String, in array: [ Track ] ) -> [ String ]
    {
        return Array( Set( array.compactMap { $0.value( forKey: key ) as? String } ) )
    }
    
    func tableViewSelectionDidChange( _ notification: Notification )
    {
        guard let tableView = notification.object as? NSTableView else
        {
            return
        }
        
        let artistFilter: ( Track ) -> Bool =
        {
            track in
            
            if self.artistsController.selectedObjects.count == 0
            {
                return true
            }
            
            for artist in self.artistsController.selectedObjects as? [ String ] ?? []
            {
                if track.artist == artist
                {
                    return true
                }
            }
            
            return false
        }
        
        let albumFilter: ( Track ) -> Bool =
        {
            track in
            
            if self.albumsController.selectedObjects.count == 0
            {
                return true
            }
            
            for album in self.albumsController.selectedObjects as? [ String ] ?? []
            {
                if track.album == album
                {
                    return true
                }
            }
            
            return false
        }
        
        self.tracksController.setSelectionIndexes( IndexSet() )
        
        if tableView.identifier == NSUserInterfaceItemIdentifier( rawValue: "Artists" )
        {
            self.tracks = self.allTracks.filter( artistFilter )
            self.albums = self.uniqueValues( for: "album", in: self.tracks )
        }
        else if tableView.identifier == NSUserInterfaceItemIdentifier( rawValue: "Albums" )
        {
            self.tracks = self.allTracks.filter( artistFilter ).filter( albumFilter )
        }
    }
}
