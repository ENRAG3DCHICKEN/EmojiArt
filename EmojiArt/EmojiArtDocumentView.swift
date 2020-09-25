//
//  ContentView.swift
//  EmojiArt
//
//  Created by ENRAG3DCHICKEN on 2020-08-18.
//  Copyright © 2020 ENRAG3DCHICKEN. All rights reserved.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    @State private var chosenPalette: String = ""
    
    @State var selectedEmojis: [EmojiArt.Emoji] = []
    
    init(document: EmojiArtDocument) {
        self.document = document
        _chosenPalette = State(wrappedValue: self.document.defaultPalette)
    }
    
    
    var body: some View {
        VStack {
            HStack {
                PaletteChooser(document: document, chosenPalette: $chosenPalette)
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(chosenPalette.map { String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size: self.defaultEmojiSize))
                                .onDrag { return NSItemProvider(object: emoji as NSString) }
                        }
                    }
                }
            }
            .padding(.horizontal)
            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay (
                        OptionalImage(uiImage: self.document.backgroundImage)
                            .scaleEffect(self.zoomScale)
                            .offset(self.panOffset)
                    )
                        .gesture(self.doubleTapToZoom(in: geometry.size))
                    if self.isLoading {
                        Image(systemName: "hourglass").imageScale(.large).spinning()
                    } else {
                        ForEach(self.document.emojis) { emoji in
                            Text(emoji.text)
                                .background(self.selectedEmojis.contains(emoji) ? Color.blue : Color.white)
                                .padding()
        
                                .font(animatableWithSize: (self.selectedEmojis.count > 0 && self.selectedEmojis.contains(emoji) == false ? emoji.fontSize * self.fixedZoomScale : emoji.fontSize * self.zoomScale))
                                .position(self.position(for: emoji, in: geometry.size))
                                .gesture(self.singleTapOnEmoji(emoji: emoji))
                                .gesture(self.dragOnEmoji(in: geometry.size))
                        }
                    }
                }
                    .clipped()
                    .gesture(self.singleTapOnBackground())
                    .gesture(self.panGesture())
                    .gesture(self.zoomGesture())
                    .edgesIgnoringSafeArea([.horizontal, .bottom])
                    .onReceive(self.document.$backgroundImage) { image in
                        self.zoomToFit(image, in: geometry.size)
                    }
                    .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                        var location = geometry.convert(location, from: .global)
                        location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                        location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                        location = CGPoint(x: location.x / self.zoomScale, y: location.y / self.zoomScale)
                        return self.drop(providers: providers, at: location)
                }
            }
        }
    }
    
    var isLoading: Bool {
        document.backgroundURL != nil && document.backgroundImage == nil
    }
    
    private func singleTapOnEmoji(emoji: EmojiArt.Emoji) -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                if self.selectedEmojis.contains(emoji) == false {
                    self.selectedEmojis.append(emoji)
                } else {
                    self.selectedEmojis.remove(at: self.selectedEmojis.firstIndex(of: emoji)!)
                }
            }
    }
    
    private func singleTapOnBackground() -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                self.selectedEmojis = []
            }
    }

    @State private var steadyStateEmojiPanOffset: CGSize = .zero
    @GestureState private var gestureEmojiPanOffset: CGSize = .zero
    
    private var EmojiPanOffset: CGSize {
        gestureEmojiPanOffset * zoomScale
    }
    
    private func dragOnEmoji(in size: CGSize) -> some Gesture {
        DragGesture()
            .updating($gestureEmojiPanOffset) { latestDragGestureValue, gestureEmojiPanOffset, transaction in
                gestureEmojiPanOffset = latestDragGestureValue.translation / self.zoomScale
        }
        .onEnded { finalDragGestureValue in

            for emojis in self.selectedEmojis {
                self.document.moveEmoji(emojis, by: (finalDragGestureValue.translation / self.zoomScale))
            }

            if finalDragGestureValue.location.x >= size.width || finalDragGestureValue.location.x <= 0 || finalDragGestureValue.location.y >= size.height || finalDragGestureValue.location.y <= 0 {
                
                if finalDragGestureValue.location.x >= size.width {
                    print("right")

                    var tempArray: [Int] = []
                    for x in 0..<self.selectedEmojis.count {
                        tempArray.append(self.selectedEmojis[x].x)
                    }
                    
                    let largestValue = tempArray.max()
                    let indexForDeletion = tempArray.firstIndex(of: largestValue!)
                    
                    self.document.removeSelectedEmojis(emoji: self.selectedEmojis[indexForDeletion!])

 
                } else if finalDragGestureValue.location.x <= 0 {
                    print("left")
                    
                    var tempArray: [Int] = []
                     for x in 0..<self.selectedEmojis.count {
                         tempArray.append(self.selectedEmojis[x].x)
                     }
                    
                    let lowestValue = tempArray.min()
                    let indexForDeletion = tempArray.firstIndex(of: lowestValue!)
                    
                    self.document.removeSelectedEmojis(emoji: self.selectedEmojis[indexForDeletion!])

                    
                } else if finalDragGestureValue.location.y >= size.height {
                    print("down")
                    
                    var tempArray: [Int] = []
                     for y in 0..<self.selectedEmojis.count {
                         tempArray.append(self.selectedEmojis[y].y)
                     }
                    
                    let largestValue = tempArray.max()
                    let indexForDeletion = tempArray.firstIndex(of: largestValue!)
                    
                    self.document.removeSelectedEmojis(emoji: self.selectedEmojis[indexForDeletion!])

                    
                } else if finalDragGestureValue.location.y <= 0 {
                    print("up")
                    
                    var tempArray: [Int] = []
                     for y in 0..<self.selectedEmojis.count {
                         tempArray.append(self.selectedEmojis[y].y)
                     }
                    
                    let lowestValue = tempArray.min()
                    let indexForDeletion = tempArray.firstIndex(of: lowestValue!)
                    

                    self.document.removeSelectedEmojis(emoji: self.selectedEmojis[indexForDeletion!])
                }
            }
            self.selectedEmojis = []

        }
    }

    //
    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private var fixedZoomScale: CGFloat {
        steadyStateZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
            
            .onEnded { finalGestureScale in
                if self.selectedEmojis.count == 0 {
                    self.steadyStateZoomScale *= finalGestureScale
                } else {
                    for emoji in self.selectedEmojis {
                        self.document.scaleEmoji(emoji, by: finalGestureScale)
                    }
                    self.selectedEmojis = []
                }
            }
    }
    
    //
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero

    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }

    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
        }
        .onEnded { finalDragGestureValue in
            self.steadyStatePanOffset = self.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
        }
    }

    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    self.zoomToFit(self.document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            self.steadyStatePanOffset = .zero
            self.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        
        if self.selectedEmojis.contains(emoji) {
            location = CGPoint(x: location.x + EmojiPanOffset.width, y: location.y + EmojiPanOffset.height)
        }

        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            print("dropped \(url)")
            self.document.backgroundURL = url
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    private let defaultEmojiSize: CGFloat = 40
}



 
