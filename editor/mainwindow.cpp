#include "mainwindow.h"
#include "canvas.h"
#include "./ui_mainwindow.h"

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    setCentralWidget(new Canvas(this));
}

MainWindow::~MainWindow()
{
    delete ui;
}

