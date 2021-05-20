//
//  GameScene.swift
//  SchoolhouseSkateboarder
//
//  Created by Даниил Миронов on 12.04.2021.
//

import SpriteKit
import Foundation

/// Идентификаторы физических объектов
///
struct PhysicsCategory {
    
    static let skater: UInt32 = 0x1 << 0
    static let brick: UInt32 = 0x1 << 1
    static let gem: UInt32 = 0x1 << 2
}

/// Уровни секций дорог
enum BrickLevel: CGFloat {
    case low = 0.0
    case high = 100.0
}

enum GameState {
    case notRun
    case run
    case paused
}

/// Главная сцена игры
///
/// Отвечает за ВСЕ происходящее на экране игры.
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    /// Объект скейтера в виде подкласса **SKSpriteNode** (спрайта)
    let skater = Skater(imageNamed: "skater")
    
    
    
    /// Массив с текущими секциями дорог в виде **SKSpriteNode** (спрайтов)
    ///
    /// Здесь храняться объекты класса **SKSpriteNode** (спрайт),
    /// которые служат для представления секций дорог (далее *секций*),
    /// которые находятся сейчас на экране.
    ///
    /// Для обновления и создания иллюзии движения дороги,
    /// используются методы **spawnbricks(atPosition:)**, **update(_:)** и **updateBricks(withScrollAmount:)**
    var bricks: [SKSpriteNode] = []
    
    
    
    /// Размер секции дороги
    ///
    /// Размер спрайта секции дороги по `X` и `Y`.
    ///
    /// Размер задаётся в методе **spawnbricks(atPosition:)**.
    ///
    /// Используется для рассчета координат при
    /// создания новых и удаления старых секций дорог.
    var brickSize: CGSize = .zero
    
    
    /// Текущий уровень секции дороги
    var brickLevel: BrickLevel = .low
    
    
    /// Скорость скролла секции дороги
    ///
    /// Нужно как аргумент функции **updateBricks(withScrollAmount:)**,
    /// чтобы рассчитать новые координаты секций дорог при их перемещении (скролле)
    ///
    /// Чем дольше сеанс попытки игрока, тем больше значение скорости скролла
    var scrollSpeed: CGFloat = 5.0
    
    /// Начальная скорость скролла секций дорог
    let startingScrollSpeed: CGFloat = 5.0
    
    
    /// Время последнего вызова метода **update(_:)** (обновление экрана)
    ///
    /// При вычитании текущего времени получается временной интервал
    /// с момента последнего обновления экрана.
    /// Полученное значение подсказывает на сколько нужно подвинуть
    /// секции дорог (спрайты), тем самым компенсируя потери кадров.
    ///
    /// Переменная опциональна, т.к. изначально обновления не было, т.е. значения тоже.
    /// Но оно появляется после первого обновления экрана – с помощью функции **update(_:)**
    var lastUpdateTime: TimeInterval?
    
    
    
    /// Скорость падения объектов
    let gravitySpeed: CGFloat = 1.5
    
    /// Массив содержащий модельки Алмазов
    var gems = [SKSpriteNode]()
    
    // Свойства для отслеживания результата
    var score: Int = 0
    var highScore: Int = 0
    var lastScoreUpdateTime: TimeInterval = 0.0
    
    /// Текущее состояние игрового процесса
    ///
    /// Данное свойство имеет всего 2 варианта значения: **.run** и **.notRun**
    var gameState: GameState = .notRun
    
    
    // MARK: Мои свойства
    
    var safeCountBrickX: UInt = 20
    var safeCountBrickY: UInt = 20

    
    /// Вызывается при первом запуске  (аналог viewDidLoad)
    ///
    /// Данная функция нужна для предварительной настройки Scene
    override func didMove(to view: SKView) {
        
        // Задаём гравитацию физике
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -6.0)
        
        // Обозначаем сцену как делегат контактов
        physicsWorld.contactDelegate = self
        
        // Задаём скорость физике
        physicsWorld.speed = CGFloat(1.0)
        
        // Точка привязки для Background (SKSpriteNode)
        anchorPoint = CGPoint.zero
        
        // Инициализация спрайта Background, на основе изображения из Assets
        let background = SKSpriteNode(imageNamed: "background")
        
        // Получаем значения координат центра текущей Scene
        let xMid = frame.midX
        let yMid = frame.midY
        
        // Задаем точку привязки для Background (спрайта)
        background.position = CGPoint(x: xMid, y: yMid)
        
        // Добавляем Background (SKSpriteNode) на Scene (тоже SKSpriteNode)
        addChild(background)
        
        // Добавляем скейтершу (SKSpriteNode)
        addChild(skater)
        
        // Устанавливавем физические свойства модельке скейтерши
        skater.setupPhysicsBody()
        
        /// Селектор (ссылка) на функцию, которая будет срабатывать при нажатии на экран
        let tapMethod = #selector(self.handleTap(tapGesture:))
        
        /// Распознаватель жестов: **нажатие на экран**
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod)
        
        // Добавляем распознаватель жестов на сцену
        view.addGestureRecognizer(tapGesture)
        
        // Добавляем слой меню с текстом "Нажмите, чтобы играть"
        let menuLayer = MenuLayer(color: UIColor.black.withAlphaComponent(0.4), size: frame.size)
        
        menuLayer.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        menuLayer.position = CGPoint(x: 0.0, y: 0.0)
        menuLayer.zPosition = 30
        menuLayer.name = "menuLayer"
        
        menuLayer.display(message: "Нажмите, чтобы играть!", score: nil)
        
        addChild(menuLayer)
        
        // Установить надписи
        setupTextLabel()
    }
    
    /// Возвращение модели Скейтерши на начальную позицию
    ///
    /// Данная функция перемещает позицию объекта **skater** (класса Skater подкласса SKSpriteNode)
    /// в старотовую позицию игровой сцены **GameScene**.
    ///
    /// Несмотря на то, что перемещение скейтера лишь иллюзия, данная функция необходима,
    /// когда моделька остановилась в момент прыжка или падения (например, при перезапуске)
    func resetSkater() {
        
        // Координата X в левой четверти экрана
        let skaterX = frame.midX / 2 // Центр GameScene деленная на половину (в 1/4 сцены)
        
        // Координата Y на уровне секций дорог
        let skaterY = skater.frame.height / 2.0 + 64.0 // Половина высоты модельки + размер секции дороги
        
        // Изменение позиции модельки (св. SKSpriteNode)
        skater.position = CGPoint(x: skaterX, y: skaterY)
        
        // Изменение уровня наложения модельки среди других спрайтов (св. SKSpriteNode)
        skater.zPosition = 10
        
        // Изменение расстояния над землей (св. Skater)
        skater.minimumY = skaterY
        
        // Уменьшение вращения модели скейтерши
        skater.zRotation = 0.0
        skater.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
        skater.physicsBody?.angularVelocity = 0.0
    }
    
    
    /// Функция отвечает за старт игры
    func startGame() {
        
        resetSkater()
        updateHighScoreLabelText()
        scrollSpeed = startingScrollSpeed
        lastUpdateTime = nil
        brickLevel = .low
        safeCountBrickX = 20
        safeCountBrickY = 20
        score = 0
        gameState = .run
        
        // Стераем секции дороги
        for brick in bricks {
            
            brick.removeFromParent()
        }
        
        bricks.removeAll(keepingCapacity: true)
        
        // Стераем Алмазы
        for gem in gems {
            
            removeGem(gem)
        }
        
        if let menuLayer = childNode(withName: "menuLayer") {
            
            menuLayer.removeFromParent()
        }
    }
    
    
    /// Функция отвечает за Game Over
    func gameOver() {
        
        gameState = .notRun
        
        if (score > highScore) {
            highScore = score
        }
        
        // Добавляем слой меню с текстом "Игра окончена!"
        let menuLayer = MenuLayer(color: UIColor.black.withAlphaComponent(0.4), size: frame.size)
        
        menuLayer.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        menuLayer.position = CGPoint(x: 0.0, y: 0.0)
        menuLayer.zPosition = 30
        menuLayer.name = "menuLayer"
        
        menuLayer.display(message: "Игра окончена!", score: score)
        
        addChild(menuLayer)
    }
    
    
    /// Установить надписи на сцену
    func setupTextLabel() {
        
        // Надпись "очки"
        let scoreTextLabel: SKLabelNode = SKLabelNode(text: "очки:")
        scoreTextLabel.position = CGPoint(x: 32, y: 5)
        scoreTextLabel.fontName = "Courier-Bold"
        scoreTextLabel.fontSize = 14
        scoreTextLabel.zPosition = 20
        
        // Число текущих очков
        let scoreLabel: SKLabelNode = SKLabelNode(text: "0")
        scoreLabel.name = "scoreLabel"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 62, y: 5)
        scoreLabel.fontName = "Courier-Bold"
        scoreLabel.fontSize = 14
        scoreLabel.zPosition = 20
        
        // Надпись "лучший результат"
        let highScoreTextLabel: SKLabelNode = SKLabelNode(text: "лучший результат:")
        highScoreTextLabel.position = CGPoint(x: frame.size.width - 64, y: frame.size.height - 20)
        highScoreTextLabel.horizontalAlignmentMode = .right
        highScoreTextLabel.fontName = "Courier-Bold"
        highScoreTextLabel.fontSize = 14
        highScoreTextLabel.zPosition = 20
        
        // Надпись "лучший результат"
        let highScoreLabel: SKLabelNode = SKLabelNode(text: "0")
        highScoreLabel.name = "highScoreLabel"
        highScoreLabel.position = CGPoint(x: frame.size.width - 8, y: frame.size.height - 20)
        highScoreLabel.horizontalAlignmentMode = .right
        highScoreLabel.fontName = "Courier-Bold"
        highScoreLabel.fontSize = 14
        highScoreLabel.zPosition = 20
        
        addChild(highScoreTextLabel)
        addChild(scoreTextLabel)
        addChild(scoreLabel)
        addChild(highScoreLabel)
    }
    
    /// Создает новую секцию дороги на сцене и возвращает её
    ///
    /// Функция создает новую секцию дороги в виде **SKSpriteNode** для сцены **GameScene**,
    /// в процессе добавляя её на позицию экрана, заданную аргументом **atPosition** и
    /// обновляя свойство **brickSize**.
    ///
    /// Уровень нового спрайта (zPosition) = 8
    ///
    /// - Parameter atPosition: Координаты для позиции новой секции дороги
    /// - Returns: Секция дороги как объект класса **SKSpriteNode**
    func spawnBrick (atPosition position: CGPoint) -> SKSpriteNode {
        
        /// Новая секция дороги
        ///
        /// Инициализируется с помощью ассета "sidewalk".
        let brick = SKSpriteNode(imageNamed: "sidewalk")
        
        // Изменение позиции на экране
        brick.position = position
        
        // Задали уровень наложения
        brick.zPosition = 8
        
        // Добавили спрайт на экран
        addChild(brick)
        
        // Обновили размер последней секции дороги (св. GameScene)
        brickSize = brick.size
        
        // Добавления секции дороги в массив с «живыми» спрайтами
        bricks.append(brick)
        
        // Задаем физическую форму для спрайта секции дороги
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size, center: brick.centerRect.origin)
        
        // Убираем гравитацию у спрайта секции дороги
        brick.physicsBody?.affectedByGravity = false
        
        // Задаем категорию физической формы
        brick.physicsBody?.categoryBitMask = PhysicsCategory.brick
        
        // Задаем категории с которыми можно сталкиваться
        brick.physicsBody?.collisionBitMask = 0 // Секция ни с чем не сталкивается
        
        return brick
    }
    
    
    /// Создает алмаз в игре
    ///
    /// Исходя из аргмента, хранящий координаты для нового алмаза,
    /// на сцене игры создается алмаз, а в массив добавляется его спрайт
    func spawnGem(atPosition position: CGPoint) {
        
        let gem = SKSpriteNode(imageNamed: "gem")
        
        gem.position = position
        gem.zPosition = 9
        
        addChild(gem)
        
        gem.physicsBody = SKPhysicsBody(rectangleOf: gem.size, center: gem.centerRect.origin)
        
        gem.physicsBody?.categoryBitMask = PhysicsCategory.gem
        gem.physicsBody?.affectedByGravity = false
        
        gems.append(gem)
        
        // Эти строки не обязательны, т.к. категории для
        // контактов и столкновений заданы у физической формы skater
            // gem.physicsBody?.contactTestBitMask = PhysicsCategory.skater
            // gem.physicsBody?.collisionBitMask = 0
    }
    
    
    /// Удаление алмаза из игры
    func removeGem(_ gem: SKSpriteNode) {
        
        // Удаление спрайта со сцены
        gem.removeFromParent()
        
        // Удаление алмаза из массива по индексу
        if let indexGem = gems.index(of: gem) {
            gems.remove(at: indexGem)
        }
        
    }
    
    
    /// Обновление секций дорог
    ///
    /// Функция вызывается при каждом обновлении экрана функцией **update(_:)**,
    /// чтобы «проскроллить» секции дорог (иллюзия перемещения модельки),
    /// создать новые спрайты справа и удалить ненужные (вышедшие за левый край сцены) из массива **bricks**
    ///
    /// - Parameter withScrollAmount: на сколько нужно «проскроллить» секции дорог
    func updateBricks(withScrollAmount currentScrollAmount: CGFloat) {
        
        /// Координата Х самого крайнего спрайта секции дороги
        ///
        /// Данная переменная понадобится, чтобы узнать
        /// куда добавлять следующий спрайт секции дороги.
        ///
        /// Переменная ищет актуальное (максимальное) значение в первом цикле,
        /// а во втором используется, чтобы добавлять спрайты секций дорог,
        /// пока значение (координаты по Х), т.е. самый правый объект дороги,
        /// не будет выходит за правый край сцены **GameScene**.
        var farthestRightBrickX: CGFloat = 0.0
        
        // Перебираем все секции дорог на сцене
        for brick in bricks {
            
            /// Новая позиция по X для секции дороги (спрайта) с учётом значения скролла
            let newX = brick.position.x - currentScrollAmount
            
            // Удаление секции дороги, если она выйдет за экран
            // (-brickSize.width равен положению центру секции, вышедшей за экран)
            if (newX < (-brickSize.width)) {
                
                // Удаление спрайта из сцены
                brick.removeFromParent()
                
                // Удаление секции дороги из массива с актуальными секциями
                bricks.remove(at: bricks.index(of: brick)!)
                
            } else {
                
                // Двигаем секцию дороги, оставшуюся на экране, влево
                brick.position = CGPoint(x: newX, y: brick.position.y)
                
                // Если это самый правый спрайт секции дороги,
                // то его значение надо запомнить
                if brick.position.x > farthestRightBrickX {
                    
                    farthestRightBrickX = brick.position.x
                }
            }
            
        }
        
        
        // Цикл, наполняющий экран новыми спрайтами секций дорог,
        // пока координата по Х самого правого спрайта секции дороги
        // находить за пределами сцены
        while (farthestRightBrickX < frame.width) {
            
            /// Координата по Х для нового спрайта секции дороги
            var brickX = farthestRightBrickX + brickSize.width + 1.0 // Добавляется разрыв для видимости «скроллинга»
            
            /// Координата по  Y для нового спрайта секции дороги
            let brickY = (brickSize.height / 2.0) + brickLevel.rawValue
            
            if (safeCountBrickX == 0) {
                
                // Рандомный (5%) разрыв для прыжков
                if (arc4random_uniform(99) < 5) {
                    
                    // Ставим Алмаз
                    let newGemY = skater.size.height + CGFloat(arc4random_uniform(150))
                    let newGemX = brickX + (20.0 * scrollSpeed / 2)
                    spawnGem(atPosition: CGPoint(x: newGemX, y: newGemY))
                    
                    // Координата новой секции по X с учётом разрыва умноженое на скорость
                    brickX += 20.0 * scrollSpeed
                    
                    safeCountBrickX = 20 + UInt(scrollSpeed / 5.0)
                    
                    
                } else
                
                if (safeCountBrickY == 0) {
                    
                    // Рандомное (5%) изменение высоты секций дорог
                    if (arc4random_uniform(99) < 5) {
                        
                        if (brickLevel == .low) { brickLevel = .high } else { brickLevel = .low }
                        
                        safeCountBrickX = 20 + UInt(scrollSpeed / 5.0)
                        safeCountBrickY = 20 + UInt(scrollSpeed / 5.0)
                    }
                } else {
                    
                    safeCountBrickY -= 1
                }
                
            } else {
                safeCountBrickX -= 1
            }
            
            
            
            /// Новый спрайт секции дороги, полученный от функции **spawnBrick(atPosition:)**
            let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
            
            // Обновляем максимальную позицию
            farthestRightBrickX = newBrick.position.x
            
        }
    }
    
    /// Обновление позиций алмазов
    ///
    /// Работает аналогично **updateBricks**
    ///
    /// - Parameter withScrollAmount: на сколько нужно «проскроллить» алмазы
    func updateGems(withScrollAmount currentScrollAmount: CGFloat) {
        
        // Перебираем все алмазы на сцене
        for gem in gems {
            
            /// Новая позиция по X для алмаза (спрайта) с учётом значения скролла
            let newX = gem.position.x - currentScrollAmount
            
            // Удаление алмаза, если он выйдет за экран
            if (newX < (-gem.size.width)) {
                
                // Удаление спрайта из сцены
                removeGem(gem)
                
            } else {
                
                // Двигаем Алмаз, оставшийся на экране, влево
                gem.position = CGPoint(x: newX, y: gem.position.y)
                
            }
            
        }
    }
    
    
    /// Обновление данных по очкам
    func updateScore(withCurrentTime currentTime: TimeInterval) {
        
        // Время, прошедшее с последнего вызова функции
        let elapsedTime = currentTime - lastScoreUpdateTime
        
        if elapsedTime > 1.0 {
            score += Int(scrollSpeed)
            
            lastScoreUpdateTime = currentTime
            
            updateScoreLabelText()
        }
        
        if (score > highScore) {
            
            highScore = score
            updateHighScoreLabelText()
        }
    }
    
    /// Обновление табло с очками
    func updateScoreLabelText() {
        
        // Получаем ссылку на спрайт с текущим кол-во очков
        if let scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode {
            
            // Строка формата "00123"
            scoreLabel.text = String(format: "%05d", score)
        }
    }
    
    /// Обновление табло с рекордными очками
    func updateHighScoreLabelText() {
        
        // Получаем ссылку на спрайт с текущим кол-во очков
        if let highScoreLabel = childNode(withName: "highScoreLabel") as? SKLabelNode {
            
            // Строка формата "00123"
            highScoreLabel.text = String(format: "%05d", highScore)
        }
    }
    
    /// Обновление спрайта модельки скейтера
    ///
    /// Используется для обновления позиции модельки при прыжке
    ///
    /// - Parameter withScrollAmount: на сколько нужно «проскроллить» секции дорог
    func updateSkater(withScrollAmount currentScrollAmount: CGFloat) {
        
        // Проверка через вертикальную скорость нахождение модельки Скейтерши на земле
        if let velocityY = skater.physicsBody?.velocity.dy {
            
            if (velocityY < -100.0 || velocityY > 100.0) {
                
//                skater.isOnGround = false
            }
        }
        
        // Вышла ли моделька скейтерши за экран
        let isOffScreen = (skater.position.y < 0.0) || (skater.position.x < 0.0)
        
        
        let maxRotation = CGFloat(GLKMathDegreesToRadians(85.0))
        
        // Сильно ли перевернулась моделька скейтерши
        let isTippedOver = skater.zRotation > maxRotation || skater.zRotation < -maxRotation
        
        // Проверка на Game Over
        if (isOffScreen || isTippedOver) {
            
            gameOver()
        }
        
        /*
        // Если моделька не на дороге (а в прыжке),
        // то вычитаем из вертикальной скорости значение гравитации (gravitySpeed),
        // а саму скорость добавляем к позиции.
        // Скейтер вернется на землю, т.к. потом вертикальная скорость станет отрицательной.
        if (!skater.isOnGround) {
            
            // Уменьшаем скорость перемещения скейтера
            skater.velocity = CGPoint(x: skater.velocity.x, y: skater.velocity.y - (gravitySpeed * currentScrollAmount))
            
            // Изменяем позицию
            skater.position = CGPoint(x: skater.position.x, y: skater.position.y + (skater.velocity.y * currentScrollAmount))
        }
        
        // Если моделька приземлилась на дорогу
        if (skater.position.y <= skater.minimumY) {
            
            skater.isOnGround = true
            skater.velocity = .zero
            skater.position.y = skater.minimumY
        }
         */
    }
    
    
    
    /// Вызывается при каждой отрисовке кадра
    override func update(_ currentTime: TimeInterval) {
        
        if (gameState == .notRun) { return }
        
        /// Фактическое затраченное время на обновление
        ///
        /// Понадобиться для рассчёта компенсации при потери кадров
        ///
        /// Вычисляется вычитанием времени последнего обновления, т.е. переменной **lastTimeStamp**,
        /// из текущего времени, т.е. **curentTime**.
        var elapsedTime: TimeInterval = 0.0
        
        
        // Вычисление фактического времени на обновление (elapsedTime)
        if let lastTimeStamp = lastUpdateTime {
            
            elapsedTime = currentTime - lastTimeStamp
        }

        
        
        /// Ожидаемое затраченное время на обновление
        ///
        /// Данная игра поддерживает 60 FPS, поэтому ожидаемое время на обновление равняется 1.0 / 60.0
        let expectedElapsedTime: TimeInterval = 1.0 / 60.0
        
        /// Разница **Фактического** и **Ожидаемого** времени обновления экрана
        let scrollAdjustment = CGFloat(elapsedTime / expectedElapsedTime)
        
        // Обновление секций дорог (с учётом потери кадров)
        updateBricks(withScrollAmount: scrollSpeed * scrollAdjustment)
        
        // Обновление Алмазов (с учётом потери кадров)
        updateGems(withScrollAmount: scrollSpeed * scrollAdjustment)
        
        // Обновление состояния модельки Скейтерши
        updateSkater(withScrollAmount: scrollAdjustment)
        
        updateScore(withCurrentTime: currentTime)
        
        if (score > highScore) {
            
            highScore = score
            updateHighScoreLabelText()
        }
        
        // Запоминаем время последнего обновления экрана
        lastUpdateTime = currentTime
        
        // Увеличение скорость скрола секций дорог
        scrollSpeed += 0.005
        
    }
    
    
    /// Функция при нажатии на экран
    ///
    /// При нажатии на экран скейтер должен прыгнуть. Прыжок не может совершиться,
    /// если моделька находиться не на земле – проверяется с помощью **skater.isOnGround**.
    /// Прыжок реализуется с помощью импульсивной силы из **SKPhysicsContactDelegate**.
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        
        if (gameState == .run) {
            
            // Проверка на нохождение скейтерши на земле
            if skater.isOnGround {
                
                run(SKAction.playSoundFileNamed("jump.wav", waitForCompletion: false))
                skater.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 420.0))
                skater.isOnGround = false
            }
        } else
        
        if (gameState == .notRun) {
            
            startGame()
        }
        
        
        
        /* СТАРЫЙ КОД – примитивный прыжок
        // Проверка, что моделька находиться на земле,
        // чтобы недопустить «прыжок от воздуха»
        if (skater.isOnGround) {
            
            skater.velocity = CGPoint(x: 0.0, y: skater.jumpSpeed)
            skater.isOnGround = false
        }
        
        */
    }
    
    
    // MARK: SKPhysicsContactDelegate Methods
    
    /// Вызывается при контакте физических форм
    func didBegin(_ contact: SKPhysicsContact) {
        
        // Если модель скейтерши коснулась секции дороги
        if (contact.bodyA.categoryBitMask == PhysicsCategory.skater &&
                contact.bodyB.categoryBitMask == PhysicsCategory.brick) {
            
            if let velY = skater.physicsBody?.velocity.dy {
                
                if (!skater.isOnGround) && (velY < 100.0) {
                    
                    skater.createSparks()
                }
            }
            
            // То значит модель скейтерши на земле
            skater.isOnGround = true
        }
        
        // Если модель скейтерши коснулась Алмаза
        if (contact.bodyA.categoryBitMask == PhysicsCategory.skater &&
                contact.bodyB.categoryBitMask == PhysicsCategory.gem) {
            
            // Значит его надо удалить
            if let gem = contact.bodyB.node as? SKSpriteNode {
                
                removeGem(gem)
            }
            
            run( SKAction.playSoundFileNamed("gem.wav", waitForCompletion: false) )
            
            score += 10 * Int(scrollSpeed)
            updateScoreLabelText()
        }
    }

}
