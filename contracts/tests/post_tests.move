#[cfg(test)]
module suiter::post_tests {
    use suiter::post;
    use sui::tx_context;

    #[test]
    fun test_create_post() {
        let ctx = &mut tx_context::dummy();
        let author = @0x1;
        let content_hash = b"test_content";
        
        let post_obj = post::create_post(author, content_hash, ctx);
        
        assert!(post::get_author(&post_obj) == author, 1);
        assert!(post::get_attention(&post_obj) == 0, 2);
        assert!(post::get_level(&post_obj) == 1, 3);
        
        let _ = post_obj;
    }

    #[test]
    fun test_post_level_progression() {
        let ctx = &mut tx_context::dummy();
        let author = @0x1;
        let content_hash = b"test_content";
        
        let mut post_obj = post::create_post(author, content_hash, ctx);
        
        // Level 1: 0 attention
        assert!(post::get_level(&post_obj) == 1, 1);
        
        // Add 1k attention → Level 2
        post::add_attention(&mut post_obj, 1_000);
        assert!(post::get_level(&post_obj) == 2, 2);
        
        // Add 4k more → Level 3 (5k total)
        post::add_attention(&mut post_obj, 4_000);
        assert!(post::get_level(&post_obj) == 3, 3);
        
        // Add 20k more → Level 4 (25k total)
        post::add_attention(&mut post_obj, 20_000);
        assert!(post::get_level(&post_obj) == 4, 4);
        
        // Add 75k more → Level 5 (100k total)
        post::add_attention(&mut post_obj, 75_000);
        assert!(post::get_level(&post_obj) == 5, 5);
        
        let _ = post_obj;
    }

    #[test]
    fun test_add_replies() {
        let ctx = &mut tx_context::dummy();
        let author = @0x1;
        let content_hash = b"test_content";
        
        let mut post_obj = post::create_post(author, content_hash, ctx);
        
        assert!(post::get_reply_count(&post_obj) == 0, 1);
        
        post::add_reply(&mut post_obj);
        post::add_reply(&mut post_obj);
        
        assert!(post::get_reply_count(&post_obj) == 2, 2);
        
        let _ = post_obj;
    }
}
