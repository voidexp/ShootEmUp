#include "brushtoolpanel.h"
#include "ui_brushtoolpanel.h"
#include "state.h"
#include <QSpinBox>

BrushToolPanel::BrushToolPanel(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::BrushToolPanel)
{
    ui->setupUi(this);

    connect(ui->brushSize, &QSpinBox::valueChanged, [=](int size){
        State::get()->getBrush()->setSize(size);
    });

    ui->brushSize->setValue(State::get()->getBrush()->getSize());
}

BrushToolPanel::~BrushToolPanel()
{
    delete ui;
}
