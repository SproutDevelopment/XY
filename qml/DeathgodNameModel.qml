// 【筆記】文字输入框的数据模型：提供 accepted / rejected 信号与 result
import QtQuick

QtObject {
  id: root
  signal accepted()
  signal rejected()
  property string result: ""

  function initialize() {
    result = "";
  }
}
