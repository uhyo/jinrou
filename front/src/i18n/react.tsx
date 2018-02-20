import * as i18next from 'i18next';
import * as React from 'react';

import {
    bind,
} from '../util/bind';

export interface IPropI18n {
    children: (t: i18next.TranslationFunction)=> React.ReactNode;
    i18n: i18next.i18n;
    // Namespace selected for i18n instance.
    namespace?: string;
}
export interface IStateI18n {
    t: i18next.TranslationFunction;
}
/**
 * Give render props a `t`.
 */
export class I18n extends React.PureComponent<IPropI18n, IStateI18n> {
    // Cache of t.
    constructor(props: IPropI18n) {
        super(props);
        // TODO waiting for React 16.3
        this.state = {
            t: this.makeT(),
        };
    }
    public componentDidMount() {
        const {
            i18n,
        } = this.props;
        i18n.on('languageChanged', this.renewT);
    }
    public componentWillUnmount() {
        const {
            i18n,
        } = this.props;
        i18n.off('languageChanged', this.renewT);
    }
    public render() {
        const {
            children,
        } = this.props;
        const {
            t,
        } = this.state;

        return children(t);
    }
    /**
     * Make a new translation function for current props.
     */
    protected makeT(): i18next.TranslationFunction {
        const {
            i18n,
            namespace,
        } = this.props;
        const t = 
            namespace ?
            i18n.getFixedT(null, namespace) :
            i18n.t.bind(i18n);
        return t;
    }
    /**
     * Remake a new t.
     */
    @bind
    protected renewT(): void {
        console.log('renew!');
        this.setState({
            t: this.makeT(),
        });
    }
}

export interface IPropI18nInterp {
    /**
     * Object passed to the interpolation routine.
     */
    children: Record<string, React.ReactNode>;
    /**
     * i18n instance.
     */
    i18n: i18next.i18n;
    /**
     * namespace.
     */
    ns: string;
    /**
     * key string.
     */
    k: string;
}
export interface IStateI18nInterp {
    /**
     * resource strings.
     */
    resource: string[];
}
/**
 * Render given i18n key with JSX element interpolation support.
 */
export class I18nInterp extends React.PureComponent<IPropI18nInterp, IStateI18nInterp> {
    constructor(props: IPropI18nInterp) {
        super(props);

        this.state = {
            resource: this.getResource(props),
        };
    }
    public render() {
        const {
            props: {
                children,
            },
            state: {
                resource,
            },
        } = this;
        const res: Array<React.ReactNode> = [];
        let flg = false;
        for (const r of this.state.resource) {
            if (flg) {
                res.push(children[r]);
            } else {
                res.push(r);
            }
            flg = !flg;
        }
        return res;
    }
    public componentDidMount() {
        const {
            i18n,
        } = this.props;
        i18n.on('languageChanged', ()=> {
            this.setState({
                resource: this.getResource(this.props),
            });
        });
    }
    public componentWillUnmount() {
        const {
            i18n,
        } = this.props;
        i18n.off('languageChanged', ()=> {
            this.setState({
                resource: this.getResource(this.props),
            });
        });
    }
    public componentWillReceiveProps(nextProps: IPropI18nInterp) {
        // XXX React 16.3
        this.setState({
            resource: this.getResource(nextProps),
        });
    }

    /**
     * Retrieve an i18n resource from props.
     */
    protected getResource(props: IPropI18nInterp): string[] {
        const {
            i18n,
            ns,
            k,
        } = props;
        const res: string = i18n.getResource(i18n.language, ns, k);
        // XXX it cannot handle custom options.
        const result: string[] = [];
        let r;
        const reg = /\{\{(\w+)\}\}/g;
        let last = 0;
        while (r = reg.exec(res)) {
            result.push(res.substring(last, r.index));
            result.push(r[1]);
            last = reg.lastIndex;
        }
        result.push(res.slice(last));
        return result;
    }
}
