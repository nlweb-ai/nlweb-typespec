import "@typespec/http";
import "@typespec/json-schema";

@service(#{
    title: "NLWeb Protocol",
})
namespace NLWeb;

model AskRequest {
    /** natural language query (required) */
    query: string;

    /** Previous conversational context.  Should be provided in comma separated list. We would like Ask requests to be restful. Passing the previous queries enables continued conversations without the server keeping state indefinitely. */
    prev?: string[];

    /** additional context (e.g., from memory) */
    context?: string;

    /** Mode of response.  Currently available modes are to return a list of matching items, or to provide a summary answer. */
    mode?: "list" | "summary";

    /** Site:  An endpoint may provide the Ask interface for multiple sites.  Use this to specify which site(s) to include responses from. */
    site?: string;

    /** Streaming:  Indicates whether the results should be streamed back. */
    streaming?: boolean;

    /** Response format:  Optional field for future use. */
    response_format?: string;
}

/** 
 * Request for NLWeb Who 'Agent Finder' endpoint for agent discovery.
 * 
 * The Who endpoint helps discovery which agents/tools can answer a given question, allowing for agent selection before making an Ask request.
 */
model WhoRequest {
    /** Natural language query for agent discovery (required) */
    query: string;

    /** Enable streaming response */
    streaming?: boolean;

    /** Additional Constraints (filters, capabilities, etc.) */
    constr?: Record<unknown>;
}


/** Metadata for NLWeb response format */

model ResponseMeta {
    /** conversational identifier - pass-through only when there are simultaneous conversations to track */
    conversation_id?: string;

    /** protocol version */
    version: string;

    /** Allow any additional protocol-specific fields */
    ...Record<unknown>;
}

/** Natural language text content item  */
model TextContent {
    /** Must be "text" */
    type: "text";

    /** Natural language content */
    text: string;
}

/** Container for resource data with optional UI rendering info */
model Resource {
    /** Resource identifier/template reference (e.g., ui://widget/restaurant-card.html) */
    uri?: string;

    /** MIME type (e.g., text/html+skybridge for ChatGPT Apps) */
    mimeType?: string;

    /** Raw content, typically HTML for widget rendering */
    text?: string;

    /**
     * Structured data payload.
     * Can be a single object or an array of objects (potentially of different types)
     */
    data: Record<unknown> | Record<unknown>[];
}

/** Agent/tool description returned by Who endpoint */
model Agent {
    /** Type of agent (e.g., "Search Agent" or "Analytics Agent") */
    @encodedName("application/json", "@type")
    type_: string;

    /** Agent specification - structure will depend on agent type */
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
    meta: ResponseMeta;

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
    meta: ResponseMeta;

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