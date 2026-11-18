// 【死神】完整武將名字輸入。使用 FreeKill 的 askToCustomDialog。
// 只有按確定會提交文字，取消將返回空字串；伺服器再次驗證全字串。
import QtQuick
import QtQuick.Controls
import Fk

Item {
  id: root
  width: 430
  height: 196
  property var extraData: ({})

  function loadData(data) {
    extraData = data || {};
    writtenName.text = "";
    writtenName.forceActiveFocus();
  }

  function submit() {
    ClientInstance.replyToServer(writtenName.text);
  }
  function cancel() {
    ClientInstance.replyToServer("");
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
      text: "死神：請輸入一名武將的完整名字"
      color: "white"
      font.pixelSize: 19
      font.bold: true
      wrapMode: Text.Wrap
    }
    Text {
      width: parent.width
      text: "必須完全相等；空格、標點及附加文字都不計算。"
      color: "#d4ccc7"
      font.pixelSize: 13
      wrapMode: Text.Wrap
    }
    TextField {
      id: writtenName
      width: parent.width
      height: 38
      color: "black"
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
