//
//  Skater.swift
//  SchoolhouseSkateboarder
//
//  Created by Даниил Миронов on 17.04.2021.
//

import SpriteKit

/// Класс спрайта модельки скейтерши
///
/// Используется внутри сцены **GameScene** для объекта скейтера
class Skater: SKSpriteNode {
    
    /// Скорость передвижения модельки скейтерши по X и Y
    ///
    /// Изначально равно **.zero**. Увеличивается по мере длительности сеансы игровой сесии.
    /// При нажатии на экран значение по Y приравнивается к значению **jumpSpeed**.
    var velocity: CGPoint = .zero
    
    
    /// Расстояние до земли (секции дороги) модельки скейтерши
    ///
    /// Изначально равно **0.0**. Изменяется при прыжке и падении.
    /// Восстанавливает при помощи **.resetSkater()** сцены **GameScene**
    var minimumY: CGFloat = 0.0
    
    
    /// Скорость прыжка
    var jumpSpeed: CGFloat = 20.0
    
    
    /// Флаг означающий нахождение на уровне земли (секции дороги)
    var isOnGround = true
    
    
    /// Установить физическую модель для модельки скейтерши
    ///
    /// Физическая форма основана на текстуре и размере спрайта.
    ///
    /// Плотность (из которой вычисляется масса по размеру) равна *6.0*.
    /// Модельке разрешено переворачиваться,
    /// а её угловая амплитуда (сопртивление вращению) равна *1.0*.
    /// Столкновение (коллизия) есть только с brick.
    func setupPhysicsBody() {
        
        // Получаем текстуру (
        if let skaterTexture = texture {
            
            // Инициализируем физическую форму для спрайта скейтерши
            physicsBody = SKPhysicsBody(texture: skaterTexture, size: size)
        }
        
        physicsBody?.isDynamic = true
        
        physicsBody?.density = 9.0
        physicsBody?.allowsRotation = false
        physicsBody?.angularDamping = 1.0
        
        physicsBody?.categoryBitMask = PhysicsCategory.skater
        physicsBody?.collisionBitMask = PhysicsCategory.brick
        physicsBody?.contactTestBitMask = (PhysicsCategory.brick | PhysicsCategory.gem)
        
        
    }
    
    
    /// Добавляет искры под скейт модельки скейтерши
    func createSparks() {
        
        if let fileURL = Bundle.main.url(forResource: "sparks", withExtension: "sks") {
            
            do {
                let fileData = try Data(contentsOf: fileURL)
                let sparksNode = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(fileData) as! SKEmitterNode
                
                // Создает узел для эмиттера искр
                sparksNode.position = CGPoint(x: 0.0, y: -50.0)
                addChild(sparksNode)
                
                let waitAction = SKAction.wait(forDuration: 0.5)
                let removeAction = SKAction.removeFromParent()
                let waitThenRemove = SKAction.sequence([waitAction, removeAction])
                
                sparksNode.run(waitThenRemove)
                
            } catch { /* ... */ }
        }
        
        var tempSKSpriteNode = SKSpriteNode()
        var tempSKNode: SKNode = tempSKSpriteNode
        
    }
}
