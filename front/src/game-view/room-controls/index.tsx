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
}
/**
 * Buttons to control rooms, used before a game starts.
 */
export class RoomControls extends React.Component<IPropRoomControls, {}> {
  public render() {
    const { joined, owner } = this.props;
    return (
      <div>
        {joined ? (
          <button type="button">ゲームから脱退</button>
        ) : (
          <button type="button">ゲームに参加</button>
        )}
      </div>
    );
  }
}
