import { observer } from 'mobx-react';
import * as React from 'react';
import { PrizeListWrapper, PrizeGroupWrapper, PrizeTip } from '../elements';
import { PrizeStore } from '..';
import { LinkLikeButton } from '../../../common/button';
import { i18n } from '../../../i18n';
import { CachedBinder } from '../../../util/cached-binder';
import { bind } from 'bind-decorator';
import { clickPrizeLogic, isPrizeSelected } from '../logic/select';

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
  private wrapperRef = React.createRef<HTMLDivElement>();
  private dragStartHandlers = new CachedBinder<string, React.DragEvent, void>();
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
        <PrizeListWrapper shrinked={store.shrinked} ref={this.wrapperRef}>
          {store.prizeGroups.map((group, idx) => (
            <PrizeGroupWrapper key={idx}>
              {group.map(prize => (
                <li key={prize.id}>
                  <PrizeTip
                    selected={isPrizeSelected(store, prize.id)}
                    draggable
                    onDragStart={this.dragStartHandlers.bind(
                      prize.id,
                      this.dragStartHandler,
                    )}
                    onClick={() =>
                      clickPrizeLogic(store, {
                        type: 'prize',
                        value: prize.id,
                      })
                    }
                  >
                    {prize.name}
                  </PrizeTip>
                </li>
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
  @bind
  protected dragStartHandler(prizeId: string, event: React.DragEvent): void {
    event.dataTransfer.setData(
      'text/plain',
      this.props.store.prizeDisplayMap.get(prizeId) || '',
    );
    event.dataTransfer.setData(
      'text/x-prize-data',
      JSON.stringify({
        type: 'prize',
        value: prizeId,
      }),
    );
  }
}
