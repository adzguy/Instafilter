//
//  ContentView.swift
//  Instafilter
//
//  Created by Davron on 1/26/20.
//  Copyright © 2020 Davron. All rights reserved.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    
    @State private var image: Image?
    @State private var filterIntensity = 1.0
    @State private var filterRadius = 200.0
    @State private var filterScale = 10.0
    
    @State private var showingFilterSheet = false
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    
    @State private var currentFilterCrystallize = false
    @State private var currentFilterEdges = false
    @State private var currentFilterGaussianBlur = false
    @State private var currentFilterPixellate = false
    @State private var currentFilterUnsharpMask = false
    @State private var currentFilterVignette = false
    @State private var currentFilterSepiaTone = false
    
    var body: some View {
        
        let intensity = Binding<Double>(
            get: {
                self.filterIntensity
            },
            set: {
                self.filterIntensity = $0
                self.applyProcessing()
            }
        )
        
        let radius = Binding<Double>(
            get: {
                self.filterRadius
            },
            set: {
                self.filterRadius = $0
                self.applyProcessing()
            }
        )
        
        let scale = Binding<Double>(
            get: {
                self.filterScale
            },
            set: {
                self.filterScale = $0
                self.applyProcessing()
            }
        )
        
        return NavigationView{
            VStack{
                ZStack{
                    Rectangle()
                        .fill(Color.secondary)
                    
                    // display the image
                    if image != nil {
                        image?
                            .resizable()
                            .scaledToFit()
                    }
                    else {
                        Text("Tap to select a picture")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
                .onTapGesture {
                    // select an image
                    self.showingImagePicker = true
                }
                
                VStack{
                    HStack{
                        Text("Intensity")
                        Slider(value: intensity)
                    }
                    
                    HStack{
                        Text("Radius   ")
                        Slider(value: radius, in: 1...200)
                    }
                    
                    HStack{
                        Text("Scale    ")
                        Slider(value: scale, in: 1...10)
                    }
                    
                }.padding(.vertical)
                
                HStack{
                    Button(action: {
                        self.showingFilterSheet = true
                    }) {
                        // change filter
                        //self.showingFilterSheet = true

                        if currentFilterCrystallize {
                            Text("Crystallize")
                        } else if currentFilterSepiaTone {
                            Text("Sepia Tone")
                        } else if currentFilterEdges {
                            Text("Edges")
                        } else if currentFilterGaussianBlur {
                            Text("Gaussian Blur")
                        } else if currentFilterPixellate {
                            Text("Pixellate")
                        } else if currentFilterUnsharpMask {
                            Text("Unsharp Mask")
                        } else if currentFilterVignette {
                            Text("Vignette")
                        } else {
                            Text("Change filter")
                        }
                    }
                    
                    Spacer()
                    
                    Button("Save"){
                        // save the picture
                        guard let processedImage = self.processedImage else {
                            self.showingError = true
                            self.errorMessage = "Please, select an image!"
                            return
                        }
                        
                        let imageSaver = ImageSaver()
                        
                        imageSaver.successHandler = {
                            print("Success")
                        }
                        
                        imageSaver.errorHandler = {
                            print("Oops: \($0.localizedDescription)")
                        }
                        
                        imageSaver.writeToPhotoAlbum(image: processedImage)
                    }
                    .alert(isPresented: $showingError) {
                        Alert(title: Text("No image to save"), message: Text(self.errorMessage), dismissButton: .default(Text("OK")))
                    }
                }
            }
            .padding()
            .navigationBarTitle("Instafilter")
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage){
                ImagePicker(image: self.$inputImage)
            }
            .actionSheet(isPresented: $showingFilterSheet) {
                ActionSheet(title: Text("Select a filter"), buttons: [
                    .default(Text("Crystallize")) {
                        self.setFilter(CIFilter.crystallize())
                        self.currentFilterCrystallize = true
                    },
                    .default(Text("Edges")) {
                        self.setFilter(CIFilter.edges())
                        self.currentFilterEdges = true
                    },
                    .default(Text("Gaussian Blur")) {
                        self.setFilter(CIFilter.gaussianBlur())
                        self.currentFilterGaussianBlur = true
                    },
                    .default(Text("Pixellate")) {
                        self.setFilter(CIFilter.pixellate())
                        self.currentFilterPixellate = true
                    },
                    .default(Text("Sepia Tone")) {
                        self.setFilter(CIFilter.sepiaTone())
                        self.currentFilterSepiaTone = true
                    },
                    .default(Text("Unsharp Mask")) {
                        self.setFilter(CIFilter.unsharpMask())
                        self.currentFilterUnsharpMask = true
                    },
                    .default(Text("Vignette")) {
                        self.setFilter(CIFilter.vignette())
                        self.currentFilterVignette = true
                    },
                    .cancel()
                ])
            }
        }
    }
    
    func loadImage() {
        reset()
        guard let inputImage = inputImage else { return }
        //image = Image(uiImage: inputImage)
        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()

//        let imageSaver = ImageSaver()
//        imageSaver.writeToPhotoAlbum(image: inputImage)
    }
    
    func applyProcessing() {
        //currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterRadius, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterScale, forKey: kCIInputScaleKey) }

        guard let outputImage = currentFilter.outputImage else { return }

        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgimg)
            image = Image(uiImage: uiImage)
            processedImage = uiImage
        }
    }
    
    func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
    }
    
    func reset() {
        filterIntensity = 1.0
        filterRadius = 200.0
        filterScale = 10.0
        
        currentFilterCrystallize = false
        currentFilterEdges = false
        currentFilterGaussianBlur = false
        currentFilterPixellate = false
        currentFilterUnsharpMask = false
        currentFilterVignette = false
        currentFilterSepiaTone = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
