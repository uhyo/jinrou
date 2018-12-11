import { Prize } from '../defs';
import { Observer, observer } from 'mobx-react';
import * as React from 'react';
import { OnePrize } from './one-prize';
import { PrizeListWrapper, PrizeGroupWrapper } from '../elements';
import { PrizeStore } from '..';
import { LinkLikeButton } from '../../../common/button';
import { i18n } from '../../../i18n';

export interface IPropPrizeList {
  i18n: i18n;
  store: PrizeStore;
}
export interface IStatePrizeList {
  /**
   * Whether list has scroll bars.
   */
  listScroll: boolean | null;
}
/**
 * Show the list of prizes.
 */
@observer
export class PrizeList extends React.Component<
  IPropPrizeList,
  IStatePrizeList
> {
  private wrapperRef = React.createRef<HTMLElement>();
  public state: IStatePrizeList = {
    listScroll: null,
  };
  public render() {
    const { i18n, store } = this.props;
    const { listScroll } = this.state;
    const shrinkHandler = () => {
      store.setShrinked(!store.shrinked);
    };
    return (
      <>
        <PrizeListWrapper shrinked={store.shrinked} innerRef={this.wrapperRef}>
          {store.prizeGroups.map((group, idx) => (
            <PrizeGroupWrapper key={idx}>
              {group.map(prize => (
                <OnePrize key={prize.id} prize={prize} />
              ))}
            </PrizeGroupWrapper>
          ))}
        </PrizeListWrapper>
        <p>
          {listScroll || !store.shrinked ? (
            <LinkLikeButton onClick={shrinkHandler}>
              {store.shrinked
                ? i18n.t('list.unshrinkLabel')
                : i18n.t('list.shrinkLabel')}
            </LinkLikeButton>
          ) : null}
        </p>
      </>
    );
  }
  public componentDidMount() {
    // check whether a scroll bar has appeared after rendering.
    const w = this.wrapperRef.current;
    if (w == null) {
      return;
    }
    const listScroll = w.scrollHeight > w.clientHeight;
    this.setState({
      listScroll,
    });
  }
}
