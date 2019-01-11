import * as React from 'react';
import styled from '../../../util/styled';
import { bind } from '../../../util/bind';
import { TranslationFunction } from '../../../i18n';

interface IPropWillForm {
  t: TranslationFunction;
  hidden?: boolean;
  /**
   * Whether the will form is open.
   */
  open: boolean;
  /**
   * Content of will.
   */
  will: string | undefined;
  /**
   * Handle of will update.
   */
  onWillChange: (content: string) => void;
}
interface IStateWillForm {
  changed: boolean;
}
/**
 * Form of will.
 */
export class WillForm extends React.PureComponent<
  IPropWillForm,
  IStateWillForm
> {
  protected textareaRef = React.createRef<HTMLTextAreaElement>();
  static getDerivedStateFromProps(props: IPropWillForm, state: IStateWillForm) {
    if (props.open === false) {
      return { changed: false };
    } else {
      return null;
    }
  }
  constructor(props: IPropWillForm) {
    super(props);
    this.state = {
      changed: false,
    };
  }
  public render() {
    const { t, hidden, open } = this.props;
    const { changed } = this.state;
    return (
      <Wrapper
        hidden={hidden}
        open={!hidden && open}
        onSubmit={this.handleSubmit}
      >
        <Content>
          <p>
            {t('game_client:speak.will.message')}
            {changed ? (
              <>
                {'　'}
                <em>{t('game_client:speak.will.changed')}</em>
              </>
            ) : null}
          </p>
          <p>
            <textarea ref={this.textareaRef} onChange={this.handleChange} />
            <input type="submit" value={t('game_client:speak.will.save')} />
          </p>
        </Content>
      </Wrapper>
    );
  }
  public componentDidUpdate(prevProps: IPropWillForm): void {
    const { current } = this.textareaRef;
    if (
      this.props.will !== prevProps.will ||
      (this.props.open && !prevProps.open)
    ) {
      // Changed will causes a forced update to DOM.
      if (current != null) {
        current.value = this.props.will || '';
      }
    }
  }
  /**
   * Handle a submission of will form.
   */
  @bind
  protected handleSubmit(e: React.SyntheticEvent<any>) {
    const { onWillChange } = this.props;
    onWillChange(
      (this.textareaRef.current && this.textareaRef.current.value) || '',
    );
    e.preventDefault();
  }
  /**
   * Handle a change to the textarea.
   */
  @bind
  protected handleChange() {
    this.setState({
      changed: true,
    });
  }
}

/**
 * Wrapper of will form.
 */
const Wrapper = styled.form<{ open: boolean }>`
  transition: height 250ms ease-out;
  display: ${({ open }) => (open ? 'block' : 'none')};
  margin: 0 -8px;

  background-color: #636363;
  color: #ffffff;
  overflow-y: hidden;
`;

const Content = styled.div`
  margin: 0.4em;

  em {
    font-style: normal;
    color: #ffff00;
    font-size: smaller;
  }

  textarea {
    width: 40em;
    max-width: 100%;
    height: 4em;
    vertical-align: text-bottom;
  }
`;
