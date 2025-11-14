import "@typespec/http";
import "@typespec/json-schema";

using TypeSpec.JsonSchema; 

@service(#{
    title: "NLWeb Protocol",
})
namespace NLWeb;

model Query {
    /** Natural language query from user.  (required) */
    text: string;

    /** Website or domain to search. May include one or many. (optional) */
    site?: string[];

    /** Geographic constraint of query (optional) */
    location?: string;

    /** price range or constraint (optional) */
    price?: string;

    /** Type of item requested (e.g., movie, recipe, customer, etc.) */
    type?: string;

    /** Allow additional domain-specific filters using schema.org vocabulary or comparable schema */
    ...Record<unknown>;

}

model Context {
    /** Array of previous queries in the conversation.  (optional) */
    prev?: string[];

    /** Free-form text paragraph describing the broader context (optional) */
    text?: string;

    /** Persistent information about the user's preferences, constraints, or characteristics */
    memory?: string[];

}

model Return_Response {   
    /** Boolean indicating whether streaming response is desired. Defaults to true. (true or false) */
    streaming?: boolean = true;

    /** Response format specification, e.g., chatgpt_app, etc. (optional) */
    format?: string; 

    /** Response mode such as list, summarize, etc. (optional) */
    mode?: string;

    /** Language code (e.g., en, fr, es) for the response. (optional) */
    lang?: string;

    /** Type of client making the request, for example, mobile, desktop, etc. (optional) */
    client_type?: "mobile" | "desktop" | "tablet" | "web";

}

model Meta {
    /** Identifier for tracking the conversation across multiple queries. (optional) */
    conversation_id?: string;

    /** API version number being used (optional) */
    api_version?: string;

    /** Request ID to check status of a previous Promise response. Only used when polling for async results. (optional) */
    request_id?: string;

}

model AskRequest {
    /** Specifies the user's current request and associated query parameters in natural language. (required) */
    query: Query;

    /** Provides contextual information about the query to help the agent better understand and respond to the request.  Context can be communicated in multiple ways depending on what information is available and relevant. (optional) */
    context?: Context;

    /** Specifies expectations and requirements for how the return response should be formatted and delivered. (optional) */
    return_response?: Return_Response;

    /** Contains metadata about the request itself, including requested version number of the protocol and tracking information. */
    meta?: Meta;
}

/** 
 * Request for NLWeb Who 'Agent Finder' endpoint for agent discovery.
 * 
 * The Who endpoint helps discovery which agents/tools can answer a given question, allowing for agent selection before making an Ask request.
 */
model WhoRequest {
    /** Natural language query for agent discovery (required) */
    query: string;

    /** Enable streaming response.  Defaults to true. (optional) */
    streaming?: boolean = true;

    /** Conversational identifier - pass-through only when there are simultaneous conversations to track (optional) */
    conversation_id?: string;
    
    /** Additional Constraints (filters, capabilities, etc.) */
    constr?: Record<unknown>;
}


/** Metadata for NLWeb 'Ask' response format */

model AskResponseMeta {
    /** Conversational identifier - pass-through only when there are simultaneous conversations to track (optional) */
    conversation_id?: string;

    /** Describes the type of response being sent.  Answer responds to the user query.  Elicitation allows the server to request additional information to carry out the task, and Promise allows for async task status checks. (optional) */
    response_type?: "Answer" | "Elicitation" | "Promise";

    /** Request ID for tracking asynchronous responses (optional) */
    request_id?: string;    

    /** protocol version (optional) */
    version?: string;

    /** Allow any additional protocol-specific fields (optional) */
    ...Record<unknown>;
}

/** Metadata for NLWeb 'Who' response format */

model WhoResponseMeta {
    /** conversational identifier - pass-through only when there are simultaneous conversations to track (optional) */
    conversation_id?: string;

    /** protocol version (optional) */
    version?: string;

    /** Allow any additional protocol-specific fields (optional) */
    ...Record<unknown>;
}


/** Natural language text content item (requires at least one)  */
model TextContent {
    /** Must be "text" (required) */
    type: "text";

    /** Natural language content (required) */
    text: string;
}

/** Container for resource data with optional UI rendering info */
model Resource {
    /** Resource identifier/template reference, e.g., ui://widget/restaurant-card.html (optional) */
    uri?: string;

    /** MIME type, e.g., text/html+skybridge for ChatGPT Apps. (optional) */
    mimeType?: string;

    /** Raw content, typically HTML for widget rendering (optional) */
    text?: string;

    /**
     * Structured data payload.
     * Can be a single object or an array of objects, potentially of different types.
     * (required)
     */
    data: Record<unknown> | Record<unknown>[];
}

/** Agent/tool description returned by Who endpoint */
model Agent {
    /** Type of agent, e.g., "Search Agent" or "Analytics Agent". (required) */
    @encodedName("application/json", "@type")
    type_: string;

    /** Agent specification - structure will depend on agent type (required) */
    agentSpec: Record<unknown>;
}

/** Resource content item with structured data */
model ResourceContent {
    /** must be "resource" */
    type: "resource";

    /** Resource details */
    resource: Resource;
}

/** Complete NLWeb Ask Response format */
model AskResponse {
    /** Metadata about the response */
    @encodedName("application/json", "_meta")
    meta: AskResponseMeta;

    /**
     * Array of content items (text and/or resource).
     * 
     * Constraints:
     * - Must contain at least one item
     * - Must contain at least one TextContent item
     * - May contain multiple items of each type in any order
     * 
     * Note:  The requirement for at least one TextContent item must be validated by implementations, as this constraint cannot be expressed in the type system.
     */
    @minItems(1)
    content: (TextContent | ResourceContent)[];
}

/** NLWeb Who Response */
model WhoResponse {
    /** Metadata about the response */
    @encodedName("application/json", "_meta")
    meta: WhoResponseMeta;

    /** 
     * Array of content items containing agent descriptions.
     * 
     * Constraints:
     * - Must contain at least one item
     * - Typically contains ResourceContent with Agent data
     * - May include TextContent for descriptions
     */
    @minItems(1)
    content: (TextContent | ResourceContent)[];
}