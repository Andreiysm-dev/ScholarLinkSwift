    //
    //  Landing.swift
    //  Afable_Swift_App_ScholarLink
    //
    //  Created by STUDENT on 9/2/25.
    //




    import SwiftUI

    struct LandingView: View {
        var body: some View {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Spacer()
                        HStack {
                            Text("Scholar")
                                .foregroundColor(.blue)
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Link")
                                .foregroundColor(.black)
                                .font(.title)
                                .fontWeight(.bold)
                            Image(systemName: "graduationcap.fill")
                        }
                        .padding(.horizontal, 1)
                        .padding(.vertical,20)
                        .background(Color.white)
                        .cornerRadius(20).frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                    
                        VStack {
                            HStack {
                                Text("Helping all Learners, one student at a time.")
                            }
                            .font(.title)
                            .fontWeight(.bold)
                            .padding([.bottom, .trailing], 10)
                            
                            HStack {
                                Text("ScholarLink connects learners with trusted tutors from various fields, including academics, arts, languages, music, and more.")
                            }
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .padding(.leading, 20)
                            .padding([.bottom, .trailing], 10)
                            
                            
                        }
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            NavigationLink(destination: RegisterView()) {
                                Text("Get Started")
                                    .font(.headline)
                                    .padding(.vertical, 13)
                                    .padding(.horizontal, 40)
                                    .foregroundColor(.white)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                    .padding(.leading, 160)
                            }
                            .padding(.horizontal,20)
                            Spacer()
                            }
                            
                        
                        Image("landingPicture")
                            .resizable()
                            .frame(width: 300, height: 400)
                            .padding(.horizontal, 50)
                    }
                }
        }
    }

    struct LandingView_Previews: PreviewProvider {
        static var previews: some View {
            LandingView()
        }
    }
