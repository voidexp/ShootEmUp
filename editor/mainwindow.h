#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <memory>
#include "ui_mainwindow.h"

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);

private:
    std::unique_ptr<Ui::MainWindow> ui;
};
#endif // MAINWINDOW_H
