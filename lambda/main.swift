//
//  main.swift
//  FaizMeuLambda
//
//  Created by Júlio César Flores on 21/07/2022.
//

import Foundation

var RUN = true

fileprivate let app = ApplicationRunLoop()

while RUN {
	if let command = readLine() {
		app.execute {
			print(command)
		}
		if command == "exit" {
			RUN = false
		}
	}
}


app.stop()
