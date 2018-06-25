import * as React from 'react';

export interface IPropRoomControls {
  /**
   * Whether you have already joined to to the room.
   */
  joined: boolean;
  /**
   * Whether you are an owner of the room.
   */
  owner: boolean;
  /**
   * Whether this room is old.
   */
  old: boolean;
}
/**
 * Buttons to control rooms, used before a game starts.
 */
export class RoomControls extends React.Component<IPropRoomControls, {}> {
  public render() {
    const { joined, owner, old } = this.props;
    return (
      <div>
        {joined ? (
          <>
            <button type="button">ゲームから脱退</button>
            <button
              type="button"
              title="全員が準備完了になるとゲームを開始できます。"
            >
              準備完了/準備中
            </button>
            <button
              type="button"
              title="ヘルパーになると、ゲームに参加せずに助言役になります。"
            >
              ヘルパー
            </button>
          </>
        ) : (
          <button type="button">ゲームに参加</button>
        )}
        {owner ? (
          <>
            <button type="button">ゲーム開始画面を開く</button>
            <button type="button">参加者を追い出す</button>
            <button type="button">[ready]を初期化する</button>
          </>
        ) : null}
        {owner || old ? (
          <button type="button">この部屋を廃村にする</button>
        ) : null}
      </div>
    );
  }
}
