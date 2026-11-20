// 【筆記】猜测武将名称的文字输入框。
// 按“確定”提交输入的文字；按“取消”返回空字符串。伺服器会再次核对全名。
import QtQuick
import QtQuick.Controls
import Fk

Item {
  id: root
  width: 430
  height: 196
  property var dataModel
  // 房间界面用 finished() 关闭弹窗（超时或有新请求时也会调用）
  signal finished()

  property bool closed: false

  function reply(text) {
    if (closed) return;
    closed = true;
    try {
      if (dataModel) {
        dataModel.result = text;
        if (text === "") dataModel.rejected(); else dataModel.accepted();
      } else {
        ClientInstance.replyToServer("", text);
      }
    } catch (e) {
      console.warn("DeathgodNameInput reply failed: " + e);
    }
    // 不论房间界面有没有关闭弹窗，都自己关闭一次
    if (root) root.finished();
  }

  function submit() { reply(writtenName.text); }
  function cancel() { reply(""); }

  Component.onCompleted: writtenName.forceActiveFocus()

  // 保险：时间到后自己关闭（正常情况下房间界面会先关闭它）
  Timer {
    interval: (typeof Config !== "undefined" && Config.roomTimeout ? Config.roomTimeout : 60) * 1000 + 300
    running: true
    repeat: false
    onTriggered: { if (!root.closed) { root.closed = true; root.finished(); } }
  }

  Rectangle {
    anchors.fill: parent
    color: "#24242c"
    radius: 9
    border.color: "#ae9385"
    border.width: 1
  }
  Column {
    anchors.fill: parent
    anchors.margins: 18
    spacing: 12
    Text {
      width: parent.width
      text: "筆記：請輸入你猜測的武將名字"
      color: "white"
      font.pixelSize: 19
      font.bold: true
      wrapMode: Text.Wrap
    }
    Text {
      width: parent.width
      text: "必須與該角色的武將名字完全相同。"
      color: "#d4ccc7"
      font.pixelSize: 13
      wrapMode: Text.Wrap
    }
    TextField {
      id: writtenName
      width: parent.width
      height: 38
      color: "white"
      selectByMouse: true
      maximumLength: 96
      placeholderText: "例如：安娜"
      onAccepted: root.submit()
    }
    Row {
      anchors.right: parent.right
      spacing: 14
      Button {
        text: "取消"
        onClicked: root.cancel()
      }
      Button {
        text: "確定"
        enabled: writtenName.text.length > 0
        onClicked: root.submit()
      }
    }
  }
}
