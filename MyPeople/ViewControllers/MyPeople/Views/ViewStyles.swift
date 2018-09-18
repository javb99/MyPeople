//
//  ViewStyles.swift
//  MyPeople
//
//  Created by Joseph Van Boxtel on 9/17/18.
//  Copyright © 2018 Joseph Van Boxtel. All rights reserved.
//

import UIKit

extension UIButton {
    func standardStyle() {
        border(of: .orange, width: 2)
        roundedAndInset()
        setTitleColor(.orange, for: .normal)
        setTitleColor(UIColor.darkGray, for: .highlighted)
        backgroundColor = .white
    }
}
