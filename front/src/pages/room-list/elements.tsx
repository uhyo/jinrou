import styled from '../../util/styled';
import { AppStyling } from '../../styles/phone';
import { phone } from '../../common/media';

/**
 * Wrapper of whole app.
 * @package
 */
export const Wrapper = styled(AppStyling)`
  padding: 0 20px;
`;

/**
 * Wrapper of navigation.
 * @package
 */
export const Navigation = styled.div`
  position: sticky;
  top: 0;
  left: 0;
  margin: 0 -20px;
  padding: 0 20px;
  z-index: 1;

  background-color: white;
`;
/**
 * Wrapper of navigation links.
 * @package
 */
export const NavLinks = styled.p`
  margin: 0;
  display: flex;
  flex-flow: row wrap;

  a {
    display: block;
    flex: auto 0 0;
    margin: 0.4em 0;
    padding: 0 0.3em;

    ${phone`
      padding: 0 0.6em;
    `} &:not(:first-of-type) {
      border-left: 1px solid currentColor;
    }
  }
`;

/**
 * Wrapper of room list.
 * @package
 */
export const RoomListWrapper = styled.div`
  width: fit-content;
  padding-bottom: 0.3em;

  ${phone`
    width: 100%;
  `};
`;

/**
 * Wrapper of one room.
 * @package
 */
export const RoomWrapper = styled.div`
  position: relative;
  left: 0;
  top: 0;
  margin: 0.3em 0;
  padding: 0.3em 0.8em;
  box-shadow: 3px 3px 6px #888888;
  display: flex;
  flex-flow: row wrap;
  align-items: baseline;
`;

/**
 * Name of room.
 * @package
 */
export const RoomName = styled.a`
  flex: 100% 0 0;
  display: block;
  word-break: break-all;
  font-size: 1.1em;
  text-decoration: none;

  /* expand link to whole box. */
  &::after {
    content: '';
    position: absolute;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
  }

  ${phone`
    flex: auto 0 1;
  `};
`;

/**
 * Status texts.
 * @package
 */
export const StatusLine = styled.div`
  flex: 100% 0 0;
  display: flex;
  flex-flow: row wrap;
  margin: 0.2em 0 0 0;
  font-size: 0.9em;
  color: #666666;
  line-height: 1.1;
`;

/**
 * Room status.
 */
export const RoomStatusLine = styled(StatusLine)`
  ${phone`
    flex: auto 1 1;
  `};
`;

/**
 * Owner info.
 */
export const OwnerStatusLine = styled(StatusLine)`
  ${phone`
  `};
`;

/**
 * Common style of status tip.
 */
export const StatusTip = styled.span`
  flex: auto 0 0;
  margin: 0 0.4em;
`;

/**
 * Room status components
 */
export const roomStatus = {
  waiting: styled(StatusTip)`
    color: #ff3333;
  `,
  playing: styled(StatusTip)`
    color: #4444ff;
  `,
  end: styled(StatusTip)`
    color: #777777;
  `,
};

/**
 * Locked room
 */
export const Locked = styled(StatusTip)`
  color: #a58a00;
`;

/**
 * Has GM mark
 */
export const HasGM = StatusTip;

/**
 * Blind mode mark
 */
export const Blind = StatusTip;

/**
 * Wrapper of room owner part
 */
export const RoomOwner = styled(StatusTip)`
  a {
    /* needed to make owner link clickable */
    position: relative;
    /* give some space to the link */
    padding: 0.3em;
  }
`;

/**
 * Wrapper of room opem time
 */
export const RoomOpenTime = styled(StatusTip)`
  flex-basis: 22ex;
`;

/**
 * Wrapper of room commentk
 */
export const Comment = styled(StatusTip)`
  flex-shrink: 1;
  word-break: break-all;
`;
