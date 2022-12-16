#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <memory>
#include <functional>
#include "ui_mainwindow.h"

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);

private slots:
    void onBrushAction(bool checked);

private:
    using WidgetFactory = std::function<QWidget*(void)>;
    void createToolBars();
    void ensureToolWidget(const QString &toolName, WidgetFactory factory);
    void hideToolWidget();

    std::unique_ptr<Ui::MainWindow> ui;
};
#endif // MAINWINDOW_H