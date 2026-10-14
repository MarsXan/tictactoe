//
//  TicTacToeApp.swift
//  TicTacToe
//
//  Created by Mohsen Mokhtari on 14/10/2026.
//

import SwiftUI

@main
struct TicTacToeApp: App {
    @State private var viewModel: GameViewModel

    init() {
        _viewModel = State(initialValue: AppDIContainer.live().makeGameViewModel())
    }

    var body: some Scene {
        WindowGroup {
            GameScreen(viewModel: viewModel)
        }
    }
}
