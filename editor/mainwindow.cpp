#include "mainwindow.h"
#include "canvas.h"
#include "scene.h"
#include "brushtoolpanel.h"
#include "state.h"
#include <QToolBar>
#include <QMetaClassInfo>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    auto canvas = new Canvas{this};
    auto scene = new Scene{this};
    canvas->setScene(scene);

    setCentralWidget(canvas);
    ui->dockWidgetContents->setSizePolicy(QSizePolicy::Policy::Preferred, QSizePolicy::Policy::Fixed);

    createToolBars();
}

void MainWindow::createToolBars()
{
    auto state = State::get();

    auto bar = addToolBar("Tools");

    // Brush
    auto brushIcon = QIcon(QPixmap(":/icon-brush"));
    auto brushAction = bar->addAction(brushIcon, "Brush", QKeySequence(Qt::Key::Key_B));
    brushAction->setCheckable(true);
    connect(brushAction, &QAction::triggered, this, &MainWindow::onBrushAction);

    auto actions = addToolBar("Actions");

    // Undo
    auto undoIcon = QIcon(QPixmap(":/icon-undo"));
    auto undoAction = state->undoStack().createUndoAction(this);
    undoAction->setIcon(undoIcon);
    undoAction->setShortcut(QKeySequence::Undo);
    actions->addAction(undoAction);

    // Redo
    auto redoIcon = QIcon(QPixmap(":/icon-redo"));
    auto redoAction = state->undoStack().createRedoAction(this);
    redoAction->setIcon(redoIcon);
    redoAction->setShortcut(QKeySequence::Redo);
    actions->addAction(redoAction);
}

void MainWindow::onBrushAction(bool checked)
{
    if (checked)
    {
        ensureToolWidget("Brush", [=](){ return new BrushToolPanel{this};});
        State::get()->setActiveTool(State::Tool::BRUSH);
        qDebug() << "Using brush tool";
    }
    else
    {
        ui->toolOptionsDock->setWidget(ui->defaultToolOptionsWidget);
        State::get()->setActiveTool(State::Tool::NONE);
        qDebug() << "Releasing brush tool";
    }
}

void MainWindow::ensureToolWidget(const QString &toolName, MainWindow::WidgetFactory factory)
{
    // some Qt meta-class magic: check what's the current tool dock widget's name is
    // and in case it differs, create a new widget
    auto toolWidget = ui->toolOptionsDock->widget();
    auto toolWidgetMeta = toolWidget->metaObject();
    auto currentToolName = toolWidgetMeta->classInfo(toolWidgetMeta->indexOfClassInfo("tool")).value();
    if (currentToolName != toolName)
    {
        ui->toolOptionsDock->setWidget(factory());
    }
}

void MainWindow::hideToolWidget()
{
    ui->toolOptionsDock->setWidget(ui->defaultToolOptionsWidget);
}
