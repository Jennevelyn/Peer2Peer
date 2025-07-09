//
//  ContentView.swift
//  TapWwar
//
//  Created by Jennifer Evelyn on 09/07/25.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var peerSession = MultipeerSession()
    @State private var myTapCount = 0
    @State private var gameOver = false
    @State private var winner: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("🔥 TAP WAR 🔥")
                .font(.largeTitle)
                .bold()

            Text("Your taps: \(myTapCount)")
                .font(.title2)

            VStack(alignment: .leading) {
                Text("Others:")
                    .font(.headline)
                ForEach(Array(peerSession.peerTapCounts.keys), id: \.self) { peer in
                    Text("\(peer.displayName): \(peerSession.peerTapCounts[peer] ?? 0)")
                }
            }
            .padding()

            Button(action: {
                myTapCount += 1
                peerSession.sendTapCount(myTapCount)
                checkWinner()
            }) {
                Text("TAP ME!")
                    .font(.title)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }

            if !peerSession.connectedPeers.isEmpty {
                Text("Connected to: \(peerSession.connectedPeers.map { $0.displayName }.joined(separator: ", "))")
                    .font(.footnote)
                    .foregroundColor(.gray)
            } else {
                Text("Looking for players...")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .alert(isPresented: $gameOver) {
            Alert(title: Text("Game Over"),
                  message: Text(winner == UIDevice.current.name ? "You win!" : "\(winner ?? "Someone") wins!"),
                  dismissButton: .default(Text("OK")))
        }
    }
    

    func checkWinner() {
        if myTapCount >= 10 {
            winner = UIDevice.current.name
            gameOver = true
        } else {
            for (peer, tap) in peerSession.peerTapCounts {
                if tap >= 10 {
                    winner = peer.displayName
                    gameOver = true
                    break
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
