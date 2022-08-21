#ifndef BRUSHTOOLPANEL_H
#define BRUSHTOOLPANEL_H

#include <QWidget>

namespace Ui {
class BrushToolPanel;
}

class BrushToolPanel : public QWidget
{
    Q_OBJECT
    Q_CLASSINFO("tool", "Brush")

public:
    explicit BrushToolPanel(QWidget *parent = nullptr);
    ~BrushToolPanel();

private:
    Ui::BrushToolPanel *ui;
};

#endif // BRUSHTOOLPANEL_H
